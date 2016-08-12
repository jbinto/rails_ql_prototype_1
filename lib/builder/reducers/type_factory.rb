module RailsQL
  module Builder
    class TypeFactory

      def self.build!(variable_builders:, **build_args)
        self.new(variable_builders: variable_builders).build! build_args
      end

      def initialize(variable_builders:)
        @variable_builders = variable_builders
      end

      # Recursively build and return an instance of `type_klass` and it's
      # children based on the builder, field definition and ctx.
      def visit_node(
        field_definition: nil,
        type_klass:,
        node:
        parent_nodes:
      )
        raise "node.type cannot be nil" if node.type.nil?
        raise "node.ctx cannot be nil" if node.ctx.nil?
        # Skip the root, it's already instantiated
        return node if node.root?

        parent_ctx = parent_nodes.last.ctx

        type = type_klass.new(
          ctx: parent_ctx.merge(field_definition.try(:child_ctx) || {}),
          root: node.root?,
          field_definition: field_definition,
          aliased_as: node.aliased_as || node.name
        )
        type.model = model
        node.type = type

        node
      end

      def end_visit_node(
        node:
        parent_nodes:
      )
        child_types = node.child_nodes.map &:type
        if node.input? && node.is_a? RailsQL::Type::List
          node.list_of_resolved_types = child_types
        end
        if node.modifier_type?
          node.modified_type = child_types.first
        elsif node.directive?
          raise "TODO: directives"
          # node.args_type = node.args_node.type
          # node.modified_type = node.child_nodes.reject{|n| n.input?}.map &:type
        elsif node.union?
          raise "TODO: unions"
        else
          node.field_types = node.child_nodes.map &:type
        end
      end

    end
  end
end
