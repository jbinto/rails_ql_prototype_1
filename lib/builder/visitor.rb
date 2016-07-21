require 'graphql/parser'

module RailsQL
  module Builder
    class Visitor < GraphQL::Parser::Visitor

      attr_reader :root_builders, :variable_definitions

      def initialize(query_root_builder:, mutation_root_builder: nil)
        @query_root_prototype = query_root_builder
        @mutation_root_prototype = mutation_root_builder
        @root_builders = []
        @fragment_builders = {}
        @builder_stack = []
        @node_stack = []
        @current_operation = :query
        @variable_definitions = {}
      end


      # Name
      # ========================================================================

      def visit_name(node)
        ap @node_stack
        @current_name = node.value
        if @node_stack.last(2) == [:variable_definition, :variable]
          visit_variable_definition_name node
        elsif @node_stack.last(2) == [:variable_definition, :named_type]
          visit_variable_definition_named_type node
        elsif @node_stack.last(2) == [:inline_fragment, :named_type]
          visit_inline_fragment_type_name node
        else
          case @node_stack.last
          when :field then visit_field_name node
          when :fragment_spread then visit_fragment_spread_name node
          when :fragment_definition then visit_fragment_definition_name node
          when :argument then visit_argument_name node
          when :variable then visit_variable_name node
          end
        end
        visit_node! :name, node
      end

      # Args
      # ========================================================================

      # This is used directly by the variables_parser
      def visit_arg_value(node)
        method =
          if current_type_builder.is_input?
            :add_child_builder!
          else
            :add_arg_builder!
          end
        input_builder = current_type_builder.send(method,
          name: @current_name,
          model: node.value
        )
        @builder_stack.push input_builder
        visit_node! :arg_value, node
      end

      def visit_argument_name(node)
        @last_argument_name = node.value
      end

      INPUT_VALUE_SYMS = [
        :int_value,
        :boolean_value,
        :string_value,
        :object_value
      ]

      # input arg visit aliases
      INPUT_VALUE_SYMS.each do |k|
        alias_method :"visit_#{k}", :visit_arg_value
      end

      # Fragments
      # ========================================================================

      def find_or_create_fragment!(name:)
        @fragment_builders[name] ||= FragmentBuilder.new(
          fragment_name: name
        )
      end

      def begin_fragment_definition(name:)
        fragment_builder = find_or_create_fragment! name: name
        fragment_builder.define_fragment_once!
        @builder_stack.push fragment_builder
        return fragment_builder
      end

      def visit_inline_fragment(node)
        parent_builder = current_type_builder
        fragment_builder = begin_fragment_definition name: nil
        fragment_builder.type_builder = TypeBuilder.new(
          type_klass: parent_builder.type_klass
        )
        parent_builder.add_fragment_builder! fragment_builder
        visit_node! :inline_fragment, node
      end

      def visit_inline_fragment_type_name(node)
        current_type_builder.type_builder = TypeBuilder.new(
          type_klass: node.value
        )
      end

      def visit_fragment_spread_name(node)
        fragment_builder = find_or_create_fragment! name: node.value
        current_type_builder.add_fragment_builder! fragment_builder
      end

      def visit_fragment_definition_name(node)
        begin_fragment_definition name: node.value
      end

      # Operations
      # ========================================================================

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
        @builder_stack = [builder]
        visit_node! :operation_definition, node
      end

      # Variables
      # ========================================================================

      def visit_variable_name(node)
        if @variable_definitions.keys.include? node.value
          current_type_builder.add_variable(
            argument_name: @last_argument_name,
            variable_name: node.value,
            variable_type_name: @variable_definitions[node.value]
          )
        else
          raise(UndefinedVariable,
            "#{node.value} was not defined as a variable in the operation"
          )
        end
      end

      def visit_variable_definition_name(node)
        @last_defined_variable_name = node.value
      end

      def visit_variable_definition_named_type(node)
        @variable_definitions[@last_defined_variable_name] = node.value
      end

      # Fields
      # ========================================================================

      def visit_field_name(node)
        child_builder = current_type_builder.add_child_builder! name: node.value
        @builder_stack.push child_builder
      end


      # Util
      # ========================================================================

      private

      def visit_node!(sym, node)
        ap "VISIT #{sym}"
        ap node
        @node_stack.push(sym)
      end

      def end_visit_node!
        ap "END VISIT #{@node_stack.last}"
        @node_stack.pop
      end

      def end_visit_builder_node(node)
        @builder_stack.pop
        end_visit_node!
      end

      # Type builder pop aliases
      INPUT_VALUE_SYMS + [
        :field,
        :inline_fragment,
        :fragment_definition,
        :operation_definition,
      ].each do |k|
        alias_method :"end_visit_#{k}", :end_visit_builder_node
      end

      def current_type_builder
        @builder_stack.last
      end

      def method_missing(*args)
        super *args if args.length != 2
        sym, node = args
        name = sym.to_s
        if name.match /^visit_/
          visit_node! name.gsub("visit_", "").to_sym, node
        elsif name.match /^end_visit_/
          end_visit_node!
        else
          super *args
        end
      end

    end
  end
end
