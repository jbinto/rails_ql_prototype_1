require 'graphql/parser'

module RailsQL
  module Builder
    class Visitor < GraphQL::Parser::Visitor

      attr_reader :operations

      def initialize(query_root_builder:, mutation_root_builder: nil)
        @query_root_prototype = query_root_builder
        @mutation_root_prototype = mutation_root_builder
        @operations = []
        @fragment_builders = {}
        @builder_stack = []
        @node_stack = []
      end

      # Name
      # ========================================================================

      def visit_name(node)
        # ap @node_stack
        @current_name = node.value
        if @node_stack.last(2) == [:variable_definition, :variable]
          visit_variable_definition_name node
        elsif @node_stack.last(2) == [:variable_definition, :named_type]
          visit_variable_definition_named_type node
        elsif @node_stack.last(2) == [:inline_fragment, :named_type]
          visit_inline_fragment_type_name node
        elsif @node_stack.last(2) == [:fragment_definition, :named_type]
          visit_fragment_definition_type_name node
        else
          case @node_stack.last
          when :operation_definition then visit_operation_definition_name node
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
        if current_builder.is_a? VariableBuilder
          visit_variable_definition_default_value node
        else
          method =
            if current_builder.is_input?
              :add_child_builder!
            else
              :add_arg_builder!
            end
          input_builder = current_builder.send(method,
            name: @current_name,
            model: node.try(:value)
          )
          @builder_stack.push input_builder
        end
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

      def visit_fragment_definition_name(node)
        fragment_builder = find_or_create_fragment! name: node.value
        @builder_stack.push fragment_builder
      end

      def visit_fragment_definition_type_name(node)
        # TODO: whitelist the fragment type klass
        fragment_builder = current_builder
        fragment_builder.type_builder = TypeBuilder.new(
          type_klass: node.value
        )
      end

      alias_method(
        :visit_inline_fragment_type_name,
        :visit_fragment_definition_type_name
      )

      def visit_fragment_spread_name(node)
        fragment_builder = find_or_create_fragment! name: node.value
        if @builder_stack.include? fragment_builder
          raise InvalidFragment, "circular fragment reference in #{node.value}"
        end
        current_builder.add_fragment_builder! fragment_builder
      end

      def visit_inline_fragment(node)
        fragment_builder = FragmentBuilder.new inline: true
        fragment_builder.type_builder = TypeBuilder.new(
          type_klass: current_builder.type_klass
        )
        current_builder.add_fragment_builder! fragment_builder
        @builder_stack.push fragment_builder
        visit_node! :inline_fragment, node
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
        operation = Operation.new
        operation.root_builder = prototype.clone
        operation.operation_type = node.operation.to_sym
        @operations << operation
        @builder_stack = [operation.root_builder]
        visit_node! :operation_definition, node
      end

      def visit_operation_definition_name(node)
        current_operation.name = node.value
      end

      # Variables
      # ========================================================================

      def visit_variable_name(node)
        current_builder.add_variable(
          argument_name: @last_argument_name,
          variable_name: node.value,
        )
      end

      def variable_builder
        ap current_builder
        unless current_builder.is_a? VariableBuilder
          raise "not a variable definition builder"
        end
        return current_builder
      end

      def visit_variable_definition(node)
        @builder_stack.push VariableBuilder.new
        visit_node! :variable_definition, node
      end

      def visit_variable_definition_name(node)
        variable_builder.variable_name = node.value
        current_operation.variable_builders[node.value] = variable_builder
      end

      def visit_variable_definition_named_type(node)
        variable_builder.type_klass = node.value
      end

      def visit_variable_definition_default_value(node)
        builder = TypeBuilder.new(
          type_klass: variable_builder.type_klass,
          model: node.try(:value),
          is_input: true
        )
        variable_builder.default_value_builder = builder
        @builder_stack.push builder
      end

      # Fields
      # ========================================================================

      def visit_field(node)
        @alias_and_name = OpenStruct.new(name: nil, alias: nil)
        visit_node! :field, node
      end

      def visit_field_name(node)
        # Aliases parse identically to field names. If you visit two field
        # names for one field then the second one is the field name.
        if @alias_and_name.name.present?
          @alias_and_name.alias = @alias_and_name.name
        end
        @alias_and_name.name = node.value
      end

      def consume_field_alias_and_name!
        child_builder = current_builder.add_child_builder!(
          name: @alias_and_name.name,
          alias: @alias_and_name.alias
        )
        @builder_stack.push child_builder
        @alias_and_name = nil
      end

      def visit_selection_set(node)
        if @node_stack.last == :field
          consume_field_alias_and_name!
        end
        visit_node! :selection_set, node
      end

      def end_visit_field(node)
        if @node_stack.last == :field && @alias_and_name.present?
          consume_field_alias_and_name!
        end
        end_visit_builder_node node
      end

      # Util
      # ========================================================================

      private

      def tabbing
        "  "*@node_stack.length
      end

      def visit_node!(sym, node)
        @node_stack.push(sym)
        puts "#{tabbing}<#{sym}>"
        if [:name, :arg_value].include?(sym) && node.try(:value).present?
          puts "#{tabbing}  #{node.value}"
        end
      end

      def end_visit_node!
        puts tabbing + "</#{@node_stack.last}>"
        @node_stack.pop
      end

      def end_visit_builder_node(node)
        @builder_stack.pop
        end_visit_node!
      end

      # Type builder pop aliases
      (INPUT_VALUE_SYMS + [
        :inline_fragment,
        :fragment_definition,
        :operation_definition,
        :variable_definition
      ]).each do |k|
        alias_method :"end_visit_#{k}", :end_visit_builder_node
      end

      def current_builder
        @builder_stack.last
      end

      def current_operation
        @operations.last
      end

      def method_missing(*args)
        # For visit_foo's and end_visit_foo's not explicitly handled by this Visitor,
        # make sure to still push it on to the stack.
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
