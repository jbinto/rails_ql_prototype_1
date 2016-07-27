module RailsQL
  module Builder
    class TypeBuilderCollection
      attr_reader :builders, :field_definitions

      def initialize(field_definitions:)
        @field_definitions = field_definitions

        # TODO: turn into array
        #  verbatim stenography of rob follows:
        #  (why? run through everything adding all the fields that get parsed as we walk the AST.
        #  after fragments and variables resolved, check are there any duplicate field keys that
        #  have incompatible data in them)

        # right now field merging doesn't work, it clobbers conflicting fields (it should error out!)
        # TODO: actually verify this; if this is true "field merging" works in the happy cases, it's the
        # negative cases that don't work.
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

    def build_types!

    end
  end
end
