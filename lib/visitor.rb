require 'graphql/parser'

module RailsQL
  class Visitor < GraphQL::Parser::Visitor

    attr_accessor :node_stack
    attr_reader :data_type_builder_stack, :root

    def initialize(root_builder)
      @root = root_builder
      @data_type_builder_stack = [root]
      @fragments = []
      @data_type_builders = [root]
      @node_stack = []
    end

    protected

    def current_data_type_builder
      data_type_builder_stack.last
    end

    def end_visit_field(node)
      node_stack.pop
      if within_fragment_definition?
        @parent_field = nil
      elsif within_data_type?
        data_type_builder_stack.pop
      elsif within_data_type_within_fragment_definition?
        @parent_field = @parent_field[:parent]
      end
      end_visit_node :field, node
    end

    def visit_name(node)
      @current_name = node.value
      case node_stack.last
      when :field then visit_field_name node
      when :fragment_spread then visit_fragment_spread_name node
      when :fragment_definition then visit_fragment_definition_name node
      end
      visit_node :name, node
    end

    def visit_field_name(node)
      if within_fragment_definition?
        @parent_field = {
          name: node.value,
          fields: [],
          fragments: [],
          parent: nil
        }
        @current_fragment[:fields] << @parent_field
      elsif within_data_type?
        child_data_type = current_data_type_builder.add_child_builder node.value
        @data_type_builder_stack.push child_data_type
        @data_type_builders << child_data_type
      elsif within_data_type_within_fragment_definition?
        new_parent_field = {
          name: node.value,
          fields: [],
          fragments: [],
          parent: @parent_field
        }
        @parent_field[:fields] << new_parent_field
        @parent_field = new_parent_field
      end
    end

    def visit_int_value(node)
      visit_arg_value node.value.to_i
    end

    def visit_string_value(node)
      visit_arg_value node.value.to_s
    end

    def visit_boolean_value(node)
      visit_arg_value node.value
    end

    def visit_arg_value(value)
      current_data_type_builder.add_arg @current_name, value
    end

    def visit_fragment_spread_name(node)
      if within_fragment_definition?
        @current_fragment[:fragments] << node.value
      elsif within_data_type?
        current_data_type_builder.unresolved_fragments << node.value
      elsif within_data_type_within_fragment_definition?
        @parent_field[:fragments] << node.value
      end
    end

    def visit_fragment_definition_name(node)
      @current_fragment = {
        name: node.value,
        fields: [],
        fragments: []
      }
      @fragments << @current_fragment
    end

    def end_visit_fragment_definition(node)
      @current_fragment = nil
    end

    def end_visit_document(node)
      resolve_fragments!
    end

    def method_missing(*args)
      super *args if args.length != 2
      sym, node = args
      name = sym.to_s
      # puts name
      if name.match /^visit_/
        visit_node name.gsub("visit_", "").to_sym, node
      elsif name.match /^end_visit_/
        end_visit_node name.gsub("end_visit_", "").to_sym, node
      else
        super *args
      end
    end

    def visit_node(sym, node)
      # puts sym
      node_stack.push(sym)
      (@current_visitors||[]).each do |visitor|
        visitor.send(:"visit_#{sym}", node)
      end
    end

    def end_visit_node(sym, node)
      node_stack.pop
      (@current_visitors||[]).each do |visitor|
        visitor.send(:"end_visit_#{sym}", node)
      end
    end

    private

    def resolve_fragments!
      @data_type_builders.each do |data_type_builder|
        @fragments.each do |fragment|
          if data_type_builder.unresolved_fragments.include?(fragment[:name])
            apply_fragment_to_data_type_builder fragment, data_type_builder
          end
        end
      end
    end

    def apply_fragment_to_data_type_builder(fragment, data_type_builder)
      fields = fragment[:fields]
      fields += fragment[:fragments].map do |fragment_name|
        @fragments.select {|f| f[:name] == fragment_name}.first[:fields]
      end.flatten

      fields.each do |field|
        child_data_type_builder = data_type_builder.add_child_builder(
          field[:name]
        )
        apply_fragment_to_data_type_builder field, child_data_type_builder
      end if fields.any?
    end

    # helpers to indicate where in the tree traversal
    # the visitor is currently at

    # eg: {
    #   fragment fragName {
    #     here
    #   }
    # }
    def within_fragment_definition?
      return false unless @current_fragment.present?

      return !within_data_type_within_fragment_definition?
    end

    # eg: {
    #   users {
    #     here
    #   }
    # }
    def within_data_type?
      !@current_fragment.present?
    end

    # eg: {
    #   fragment fragName {
    #     users {
    #       here
    #     }
    #   }
    # }
    def within_data_type_within_fragment_definition?
      return false unless @current_fragment.present?

      @parent_field.present?
    end
  end
end
