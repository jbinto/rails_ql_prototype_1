require 'graphql/parser'

module RailsQL
  class Visitor < GraphQL::Parser::Visitor

    attr_reader :root_builders

    def initialize(query_root_builder:, mutation_root_builder:)
      @query_root_prototype = query_root_builder
      @mutation_root_prototype = mutation_root_builder
      @root_builders = []
      @union_type_builder_stack = []
      @fragments = []
      @type_builders = []
      @node_stack = []
      @current_operation = :query
      @input_object_key_stack = []
    end

    protected

    def current_type_builder
      @type_builder_stack.last
    end

    def end_visit_field(node)
      @node_stack.pop
      if within_inline_fragment?
        @parent_field = @parent_field[:parent] if @parent_field
        @union_type_builder_stack.pop
      elsif within_fragment_definition?
        @parent_field = nil
      elsif within_type?
        @type_builder_stack.pop
      elsif within_type_within_fragment_definition?
        @parent_field = @parent_field[:parent]
      end
      end_visit_node :field, node
    end

    def visit_name(node)
      ap 'name'
      ap node.value
      ap @node_stack.last
      @current_name = node.value
      case @node_stack.last
      when :field then visit_field_name node
      when :fragment_spread then visit_fragment_spread_name node
      when :fragment_definition then visit_fragment_definition_name node
      when :inline_fragment then visit_inline_fragment_name node
      when :named_type then visit_named_type_name node
      when :argument then visit_argument_name node
      end
      visit_node :name, node
    end

    def visit_argument_name(node)
      ap 'arg name'
      ap node.value
      @last_argument_name = node.value
    end

    def visit_inline_fragment(node)
      @inline_fragment = true
    end

    def end_visit_inline_fragment(node)
      if @parent_field
        @parent_field = @parent_field[:parent]
      end
      @inline_fragment = nil
    end

    def visit_named_type_name(node)
      if within_inline_fragment?
        if within_fragment_definition?
          @parent_field = new_field node.value
          @current_fragment[:inline_fragments] << @parent_field
        elsif within_type_within_fragment_definition?
          new_parent_field = new_field node.value, @parent_field
          @parent_field[:inline_fragments] << new_parent_field
          @parent_field = new_parent_field
        else
          @union_type_builder_stack.push(
            current_type_builder.add_child_builder node.value.downcase
          )
        end
      end
    end

    def visit_field_name(node)
      if within_inline_fragment?
        visit_field_name_in_inline_fragment node
      elsif within_fragment_definition?
        @parent_field = new_field node.value
        @current_fragment[:fields] << @parent_field
      elsif within_type?
        child_type = current_type_builder.add_child_builder node.value
        @type_builder_stack.push child_type
        @type_builders << child_type
      elsif within_type_within_fragment_definition?
        new_parent_field node.value
      end
    end

    def visit_field_name_in_inline_fragment(node)
      if within_fragment_definition?
        @parent_field = @current_fragment[:inline_fragments].last
        @parent_field[:fields] << new_field(node.value, @parent_field)
      elsif within_type_within_fragment_definition?
        new_parent_field node.value
      else
        @union_type_builder_stack.push(
          (@union_type_builder_stack.last || current_type_builder)
            .add_child_builder(node.value.downcase)
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

    def current_input_object
      @input_object_key_stack.inject(@input_object) do |current_input_obj, key|
        current_input_obj[key]
      end
    end

    def current_input_object=(value)
      @input_object_key_stack.inject(@input_object) do |current_input_obj, key|
        current_input_obj[key]
      end
    end

    def visit_object_value(node)
      if @input_object.nil?
        @input_object ||= {@current_name.to_sym => {}}
      else
        current_input_object[@current_name.to_sym] = {}
      end
      @input_object_key_stack.push @current_name.to_sym
    end

    def end_visit_object_value(node)
      if @input_object_key_stack.size == 1
        # the input_object has been fully built, so add to the current builder
        current_type_builder.add_arg(
          @input_object_key_stack.first.to_sym,
          @input_object[@input_object_key_stack.first]
        )
        @input_object = nil
      end
      @input_object_key_stack.pop
    end

    def visit_arg_value(value)
      if @input_object.nil?
        current_type_builder.add_arg @current_name, value
      else
        current_input_object[@current_name.to_sym] = value
      end
    end

    def visit_fragment_spread_name(node)
      if within_fragment_definition?
        @current_fragment[:fragments] << node.value
      elsif within_type?
        current_type_builder.unresolved_fragments << node.value
      elsif within_type_within_fragment_definition?
        @parent_field[:fragments] << node.value
      end
    end

    def visit_fragment_definition_name(node)
      @current_fragment = new_field node.value
      @fragments << @current_fragment
    end

    def end_visit_fragment_definition(node)
      @current_fragment = nil
    end

    def end_visit_document(node)
      resolve_fragments!
    end

    def visit_variable_definition(node)
      ap "Variable!"
      # ap node.methods - Object.methods
      ap node.default_value
      # ap node.type.to_s
      ap node.variable.methods - Object.methods
    end

    def visit_variable(node)
      ap node.methods - Object.methods
    end

    def method_missing(*args)
      super *args if args.length != 2
      sym, node = args
      name = sym.to_s
      if name.match /^visit_/
        visit_node name.gsub("visit_", "").to_sym, node
      elsif name.match /^end_visit_/
        end_visit_node name.gsub("end_visit_", "").to_sym, node
      else
        super *args
      end
    end

    def visit_operation_definition(node)
      prototype =
        if node.operation == "mutation"
          @mutation_root_prototype
        elsif node.operation == "query" || node.operation == "subscription"
          @query_root_prototype
        else
          raise "Operation not supported: #{node.operation}"
        end
      builder = prototype.clone
      @root_builders << builder
      @type_builder_stack = [builder]
    end

    def end_visit_operation_definition(node)
      @type_builder_stack = nil
    end

    def visit_node(sym, node)
      @node_stack.push(sym)
    end

    def end_visit_node(sym, node)
      @node_stack.pop
    end

    private

    def new_parent_field(name)
      new_parent_field = new_field name, @parent_field
      @parent_field[:fields] << new_parent_field
      @parent_field = new_parent_field
    end

    def new_field(name, parent=nil)
      return {
        name: name,
        fields: [],
        fragments: [],
        inline_fragments: [],
        parent: parent
      }
    end

    def resolve_fragments!
      @type_builders.each do |type_builder|
        @fragments.each do |fragment|
          if type_builder.unresolved_fragments.include?(fragment[:name])
            apply_fragment_to_type_builder fragment, type_builder
          end
        end
      end
    end

    def apply_fragment_to_type_builder(fragment, type_builder)
      fields = fragment[:fields]
      fields += fragment[:fragments].map do |fragment_name|
        @fragments.select {|f| f[:name] == fragment_name}.first[:fields]
      end.flatten

      fields.each do |field|
        child_type_builder = type_builder.add_child_builder(
          field[:name]
        )
        apply_fragment_to_type_builder field, child_type_builder
      end if fields.any?

      apply_inline_fragments_to_type_builder fragment, type_builder
    end

    def apply_inline_fragments_to_type_builder(fragment, type_builder)
      return if fragment[:inline_fragments].blank?

      fragment[:inline_fragments].each do |inline_fragment|
        child_type_builder = type_builder.add_child_builder(
          inline_fragment[:name].downcase
        )
        apply_fragment_to_type_builder(
          inline_fragment,
          child_type_builder
        )
      end
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

      return !within_type_within_fragment_definition?
    end

    # eg: {
    #   weapon {
    #     ... on sword {
    #       here
    #     }
    #     ... on crossbow {
    #     }
    #   }
    # }
    def within_inline_fragment?
      @inline_fragment.present?
    end

    # eg: {
    #   users {
    #     here
    #   }
    # }
    def within_type?
      !@current_fragment.present?
    end

    # eg: {
    #   fragment fragName {
    #     users {
    #       here
    #     }
    #   }
    # }
    def within_type_within_fragment_definition?
      return false unless @current_fragment.present?

      @parent_field.present?
    end
  end
end
