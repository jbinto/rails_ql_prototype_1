require 'graphql/parser'

module RailsQL
  module Builder
    class Visitor < GraphQL::Parser::Visitor

      attr_reader :operations

      def initialize
        @operations = []
        @fragment_nodes = {}
        @builder_node_stack = []
        @node_stack = []
      end

      # Name
      # ========================================================================

      def visit_name(ast_node)
        # ap @node_stack
        @current_name = ast_node.value
        if @node_stack.last(2) == [:variable_definition, :variable]
          visit_variable_definition_name ast_node
        elsif @node_stack.last(2) == [:variable_definition, :named_type]
          visit_variable_definition_named_type ast_node
        elsif @node_stack.last(2) == [:inline_fragment, :named_type]
          visit_inline_fragment_type_name ast_node
        elsif @node_stack.last(2) == [:fragment_definition, :named_type]
          visit_fragment_definition_type_name ast_node
        else
          case @node_stack.last
          when :operation_definition
            visit_operation_definition_name ast_node
          when :field
            visit_field_name ast_node
          when :fragment_spread
            visit_fragment_spread_name ast_node
          when :fragment_definition
            visit_fragment_definition_name ast_node
          when :argument
            visit_argument_name ast_node
          when :variable
            visit_variable_name ast_node
          when :directive
            visit_directive_name ast_node
          end
        end
        visit_ast_node! :name, ast_node
      end

      # Args
      # ========================================================================

      def visit_argument(ast_node)
        create_type_builder_if_within_field!
        @builder_node_stack.push current_builder_node.arg_type_builder
        visit_ast_node! :argument, ast_node
      end

      # This is used directly by the variables_parser
      def visit_arg_value(ast_node)
        # TODO: variables
        # if current_builder_node.is_a? VariableBuilder
        #   visit_variable_definition_default_value node
        # else
        if true
          input_builder = Node.new(
            name: @current_name,
            aliased_as: @current_name,
            model: ast_node.try(:value),
            is_input: true
          )
          current_builder_node.child_builders << input_builder
          @builder_node_stack.push input_builder
        end
        @current_name = nil
        visit_ast_node! :arg_value, ast_node
      end

      def visit_argument_name(ast_node)
        @last_argument_name = ast_node.value
      end


      INPUT_VALUE_SYMS = [
        :int_value,
        :boolean_value,
        :string_value,
        :object_value,
        :list_value
      ]

      # input arg visit aliases
      INPUT_VALUE_SYMS.each do |k|
        alias_method :"visit_#{k}", :visit_arg_value
      end

      # Fragments
      # ========================================================================

      def find_or_create_fragment!(name:)
        @fragment_nodes[name] ||= Node.new fragment_name: name
      end

      def visit_fragment_definition_name(ast_node)
        fragment_builder = find_or_create_fragment! name: ast_node.value
        @builder_node_stack << fragment_builder
      end

      def visit_fragment_type_name(ast_node)
        current_builder_node.fragment_defined_on = ast_node.value
      end

      alias_method(
        :visit_inline_fragment_type_name,
        :visit_fragment_type_name
      )

      alias_method(
        :visit_fragment_definition_type_name,
        :visit_fragment_type_name
      )

      def visit_fragment_spread_name(ast_node)
        fragment_node = find_or_create_fragment! name: ast_node.value
        current_builder_node.child_nodes << fragment_node
      end

      def visit_inline_fragment(ast_node)
        fragment_node = Node.new(
          inline_fragment: true,
          fragment_name: name
        )
        current_builder_node.child_nodes << fragment_node
        @builder_node_stack.push fragment_builder
        visit_ast_node! :inline_fragment, ast_node
      end

      # Operations
      # ========================================================================

      def visit_operation_definition(ast_node)
        if ["query", "mutation", "subscription"].exclude? ast_node.operation
          raise "Operation not supported: #{ast_node.operation}"
        end
        operation = Operation.new
        operation.root_builder = TypeBuilder.new root: true
        operation.operation_type = ast_node.operation.to_sym
        @operations << operation
        @builder_node_stack = [operation.root_builder]
        visit_ast_node! :operation_definition, ast_node
      end

      def visit_operation_definition_name(ast_node)
        current_operation.name = ast_node.value
      end

      def end_visit_operation_definition(ast_node)
        if @operations.length > 1 && @operations.any?{|op| op.name == nil}
          raise "cannot have multiple anonomous operations in a query document"
        end
        end_visit_current_builder_node ast_node
      end

      # Variables
      # ========================================================================

      def visit_variable_name(ast_node)
        variable_node = Node.new(
          name: @last_argument_name,
          aliased_as: @last_argument_name,
          variable_name: ast_node.value
        )
        current_builder_node.variables[@last_argument_name] = ast_node.value
      end

      def variable_definition_builder
        # ap current_builder_node
        unless current_builder_node.is_a? VariableDefinitionBuilder
          raise "not a variable definition builder"
        end
        return current_builder_node
      end

      def visit_variable_definition(ast_node)
        @builder_node_stack.push VariableDefinitionBuilder.new
        visit_ast_node! :variable_definition, ast_node
      end

      def visit_variable_definition_name(ast_node)
        variable_definition_builder.variable_name = ast_node.value
        current_operation.variable_builders[node.value] = variable_builder
      end

      def visit_variable_definition_named_type(ast_node)
        variable_builder.of_type = ast_node.value
      end

      def visit_variable_definition_default_value(ast_node)
        builder = Node.new(
          model: ast_node.try(:value),
          is_input: true
        )
        variable_builder.default_value_builder = builder
        @builder_node_stack.push builder
      end

      # Fields
      # ========================================================================

      def visit_field(ast_node)
        @alias_and_name = OpenStruct.new(name: nil, aliased_as: nil)
        visit_ast_node! :field, ast_node
      end

      def visit_field_name(ast_node)
        # Aliases parse identically to field names. If you visit two field
        # names for one field then the second one is the field name.
        if @alias_and_name.name.present?
          @alias_and_name.aliased_as = @alias_and_name.name
        end
        @alias_and_name.name = ast_node.value
      end

      def create_type_builder_if_within_field!
        # alias and name is only present if a type builder has not yet been
        # defined
        if @node_stack.last == :field && @alias_and_name.present?
          child_builder = Node.new(
            name: @alias_and_name.name,
            aliased_as: @alias_and_name.aliased_as || @alias_and_name.name,
            arg_type_builder: Node.new(
              is_input: true
            )
          )
          current_builder_node.child_builders <<  child_builder
          @builder_node_stack.push child_builder
          @alias_and_name = nil
        end
      end

      def visit_selection_set(ast_node)
        create_type_builder_if_within_field!
        visit_ast_node! :selection_set, ast_node
      end

      def end_visit_field(ast_node)
        create_type_builder_if_within_field!
        end_visit_current_builder_node ast_node
      end

      # Directives
      # ========================================================================

      def visit_directive(ast_node)
        visit_ast_node! :directive, ast_node
      end

      def visit_directive_name(ast_node)
        directive_builder = Node.new(
          name: current_builder_node.name,
          aliased_as: current_builder_node.aliased_as,
          directive_name: ast_node.value,
          arg_type_builder: Node.new(
            is_input: true
          )
        )
        if current_builder_node.directive?
          current_builder_node.child_builders << directive_builder
        else
          current_builder_node.first_directive_builder = directive_builder
        end
        @builder_node_stack.push directive_builder
        # replace the alias and name so that the modified type will receive an
        # empty name and alias
        @alias_and_name = OpenStruct.new(name: nil, aliased_as: nil)
      end

      # Util
      # ========================================================================

      private

      def tabbing
        "  "*@node_stack.length
      end

      def visit_ast_node!(sym, ast_node)
        @node_stack.push(sym)
        # puts "#{tabbing}<#{sym}>"
        # if [:name, :arg_value].include?(sym) && ast_node.try(:value).present?
        #   puts "#{tabbing}  #{ast_node.value}"
        # end
      end

      def end_visit_ast_node!
        # puts tabbing + "</#{@node_stack.last}>"
        @node_stack.pop
      end

      def end_visit_current_builder_node(ast_node)
        @builder_node_stack.pop
        end_visit_ast_node!
      end

      # @builder_node_stack.pop aliases
      (INPUT_VALUE_SYMS + [
        :inline_fragment,
        :fragment_definition,
        :fragment_spread,
        :variable_definition,
        :directive,
        :argument
      ]).each do |k|
        alias_method :"end_visit_#{k}", :end_visit_current_builder_node
      end

      def current_builder_node
        @builder_node_stack.last
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
          visit_ast_node! name.gsub("visit_", "").to_sym, node
        elsif name.match /^end_visit_/
          end_visit_ast_node!
        else
          super *args
        end
      end

    end
  end
end
