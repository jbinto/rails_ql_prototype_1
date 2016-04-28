# used for introspection
# the model resolves to the schema data_type class

module RailsQL
  module DataType
    class IntrospectSchema < Base
      field(:types,
        data_type: "RailsQL::DataType::Primative::JSON",
        singular: false,
        query: nil,
        resolve: ->(args, child_query){recurse_over_data_type_klasses(model)}
      )

      def recurse_over_data_type_klasses(data_type_klass, types=[])
        data_type_klass.field_definitions.map do |name, field_definition|
          klass_name = field_definition.data_type_klass.to_s.gsub(
            "RailsQL::DataType::", ""
          ).gsub(
            "Primative::", ""
          )
          next if types.any? {|t| t['name'] == klass_name}

          types << {
            "name" => klass_name,
            "description" => field_definition.data_type_klass.description
          }
          recurse_over_data_type_klasses field_definition.data_type_klass, types
        end

        types
      end

      can :read, fields: [:types]
    end
  end
end