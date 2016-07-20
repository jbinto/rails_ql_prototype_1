module RailsQL
  module Builder
    class TypeBuilderCollection
      attr_reader :builders, :field_definitions

      def initialize(field_definitions:)
        @field_definitions = field_definitions
        @builders = {}
      end

      # idempotent
      def add_builder!(name:, model: nil)
        field_definition = field_definitions[name]
        if field_definition.blank?
          raise "Invalid key #{name}"
        end
        return @builders[name] if @builders[name].present?

        type_klass = field_definition.type

        builder = Builder.new(
          type_klass: type_klass,
          args_definition: field_definition.args,
          ctx: @ctx.merge(field_definition.child_ctx),
          root: false,
          model: model
        )

        @builders[name] = builder
        return builder
      end
    end
  end
end
