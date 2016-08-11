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
        raise "Type klass cannot be nil" if type_klass.nil?
        raise "ctx cannot be nil" if ctx.nil?
        # Build ctx and opts to be passed to the `type_klass` constructor
        # TODO: move this to setting the child ctx
        child_ctx = ctx.merge(field_definition.try(:child_ctx) || {})

      end

    end
  end
end
