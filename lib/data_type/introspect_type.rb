# used for introspection
# the model resolves to the data_type class being introspected

module RailsQL
  module DataType
    class IntrospectType < Base
      field :name, data_type: :String
      field :description, data_type: :String
      field(:fields,
        optional_args: {include_deprecated: "BooleanValue"},
        data_type: "RailsQL::DataType::IntrospectField",
        singular: false,
        resolve: ->(args, child_query){
          model.field_definitions.values
        }
      )

      def name
        model.to_s.gsub("RailsQL::DataType::Primative::", "")
      end

      can :read, fields: [:name, :fields]
    end
  end
end