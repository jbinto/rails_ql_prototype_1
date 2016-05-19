require 'graphql/parser'

module RailsQL
  class Visitor < GraphQL::Parser::Visitor

    attr_accessor :node_stack
    attr_reader :data_type_builder_stack
    attr_reader :root

    def initialize(root_builder)
      @root = root_builder
      @fragments = {}
      @defined_fragments = {}
      @data_type_builder_stack = [root]
      @node_stack = []
    end

    protected

    def current_data_type_builder
      data_type_builder_stack.last
    end

    def end_visit_field(node)
      @inner_data_type = nil
      node_stack.pop
      unless @current_fragment
        data_type_builder_stack.pop
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
      name = node.value
      if @current_fragment
        @defined_fragments[@fragment_definition_name] << name
        @current_fragment[:referenced_by].each do |data_type_builder|
          @inner_data_type = data_type_builder.add_child_builder name
        end
      else
        @data_type_builder_stack.push(
          current_data_type_builder.add_child_builder(name)
        )
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
      fragment = (@fragments[node.value] ||= {referenced_by: []})

      if @defined_fragments[node.value].present?
        if @inner_data_type.present?
          @defined_fragments[node.value].each do |field|
            @inner_data_type.add_child_builder field
          end
        else
          if @current_fragment.present?
            @defined_fragments[node.value].each do |field|
              @current_fragment[:referenced_by].each do |data_type_builder|
                data_type_builder.add_child_builder(field)
              end
            end
          else
            @defined_fragments[node.value].each do |field|
              current_data_type_builder.add_child_builder(field)
            end
          end
        end
      else
        if @current_fragment.present?
          if @inner_data_type.present?
            fragment[:referenced_by] << @inner_data_type
          else
            fragment[:referenced_by] += @current_fragment[:referenced_by]
          end
        else
          fragment[:referenced_by] << current_data_type_builder
        end
      end
    end

    def visit_fragment_definition_name(node)
      @fragment_definition_name = node.value
      @defined_fragments[@fragment_definition_name] = []
      @current_fragment = @fragments[@fragment_definition_name] || {referenced_by: []}
    end

    def end_visit_fragment_definition(node)
      @inner_frag = nil
      @current_fragment = nil
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
  end
end
