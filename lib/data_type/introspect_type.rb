# used for introspection
# the model resolves to the data_type class being introspected

module RailsQL
  module DataType
    class IntrospectType < Base
      description(
        "The fundamental unit of any GraphQL Schema is the type. There are many " +
        "kinds of types in GraphQL. Depending on the kind of a type, " +
        "certain fields describe information about that type. Scalar types " +
        "provide no information beyond a name and description, while Enum types " +
        "provide their values. Object and Interface types provide the fields " +
        "they describe. Abstract types, Union and Interface, provide the Object" +
        " types possible at runtime. List and NonNull types compose other types."
      )

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

      can :read, fields: [:name, :fields, :description]
    end
  end
end