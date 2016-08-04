module RailsQL
  module Builder
    class TypeBuilderCollection

      def initialize
        # TODO: turn into array
        #  verbatim stenography of rob follows:
        #  (why? run through everything adding all the fields that get parsed as we walk the AST.
        #  after fragments and variables resolved, check are there any duplicate field keys that
        #  have incompatible data in them)

        # right now field merging doesn't work, it clobbers conflicting fields (it should error out!)
        # TODO: actually verify this; if this is true "field merging" works in the happy cases, it's the
        # negative cases that don't work.
        @type_builders = []
      end

      # idempotent
      def create_and_add_builder!(name:, field_alias:, model: nil)
        type_builder = TypeBuilder.new(
          name: name,
          field_alias: field_alias,
          root: false,
          model: model
        )

        @type_builders << type_builder
        return type_builder
      end
    end

    # idempotent
    def add_existing_builder!(name:, type_builder:)
      @type_builders << type_builder
    end

    def build_types!(field_definitions:, ctx:)
      # TODO: field merging should go here
      # Basically take 2 or more type builders, compare them and then
      # combine them and their child type builders recursively into new objects
      types = {}
      @type_builders.each do |type_builder|
        field_definition = field_definitions[type_builder.name]
        if field_definition.blank?
          raise "Invalid key #{type_builder.name}"
        end

        type = type_builder.build_type!(
          field_definition: field_definition,
          type_klass: field_definition.type_klass
        )
        types[type_builder.field_definition.name] = type
      end
      return types
    end

  end
end
