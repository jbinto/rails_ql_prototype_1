module RailsQL
  module Builder
    class TypeBuilderCollection
      attr_reader :builders, :field_definitions

      def initialize(field_definitions:)
        @field_definitions = field_definitions
        @type_builders = {}
      end

      # idempotent
      def create_and_add_builder!(name:, model: nil)
        field_definition = field_definitions[name]
        if field_definition.blank?
          raise "Invalid key #{name}"
        end
        return @type_builders[name] if @type_builders[name].present?

        type_klass = field_definition.type

        type_builder = TypeBuilder.new(
          type_klass: type_klass,
          args_definition: field_definition.args,
          ctx: @ctx.merge(field_definition.child_ctx),
          root: false,
          model: model
        )

        @type_builders[name] = type_builder
        return type_builder
      end
    end

    # idempotent
    def add_existing_builder!(name:, type_builder:)
      @type_builders[name] = type_builder
      return type_builder
    end
  end
end
