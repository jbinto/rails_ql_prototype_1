require_relative "../field/field_collection.rb"
require_relative "../field/field.rb"

module RailsQL
  module Builder
    class FieldCollectionBuilder
      attr_reader :parent_type

      def constructor(parent_type:, child_type_builders:)
        @parent_type = parent_type
        @child_type_builders = child_type_builders
      end

      def child_types
        builders = @child_type_builders
        @child_types ||= builders.transform_values do |name, builder|
          builder.build_type
        end
      end

      def fields
        fields = Field::FieldCollection.new
        child_types.each do |name, type|
          fields[name] = Field::Field.new(
            name: name,
            field_definition: parent_type.class.field_definitions[name],
            parent_type: parent_type,
            type: type
          )
        end
        return fields.freeze
      end
    end
  end
end
