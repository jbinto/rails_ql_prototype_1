# used for introspection
# the model resolves to the data_type class being introspected

module RailsQL
  module Introspection
    class Type  < RailsQL::Type
      type_name "__Type"

      description <<-eos
        The fundamental unit of any GraphQL Schema is the type. There are many
        kinds of types in GraphQL. Depending on the kind of a type,
        certain fields describe information about that type. Scalar types
        provide no information beyond a name and description, while Enum types
        provide their values. Object and Interface types provide the fields
        they describe. Abstract types, Union and Interface, provide the Object
        types possible at runtime. List and NonNull types compose other types.
      eos

      field(:kind,
        data_type: "RailsQL::Introspection::TypeKind",
        nullable: false,
        resolve: ->(args, child_query) {
          model.type_definition.kind
        }
      )

      field(:name,
        data_type: :String,
        resolve: ->(args, child_query) {
          model.type_definition.name
        }
      )

      field(:description,
        data_type: :String,
        resolve: ->(args, child_query) {
          model.type_definition.description
        }
      )

      has_many(:fields,
        description: "OBJECT and INTERFACE only",
        optional_args: {include_deprecated: {type: "Boolean"}},
        data_type: "RailsQL::Introspection::Field",
        resolve: ->(args, child_query){
          definitions = model.field_definitions
          if args[:include_deprecated] == false
            definitions = definitions.reject &:deprecated?
          end
          definitions.values
        }
      )

      # TODO: interfaces
      has_many(:interfaces,
        description: "OBJECT only",
        data_type: "RailsQL::Introspection::Type",
        resolve: ->(args, child_query) {
          []
        }
      )


      # TODO: interfaces and unions
      has_many(:possibleTypes,
        description: "INTERFACE and UNION only",
        data_type: "RailsQL::Introspection::Type",
        resolve: ->(args, child_query) {
          []
        }
      )

      # TODO: enums
      has_many(:enumValues,
        description: "ENUM only",
        data_type: "RailsQL::Introspection::EnumValue",
        resolve: ->(args, child_query) {
          model.type_definition.enum_values.values
        }
      )

      has_many(:inputFields,
        description: "INPUT_OBJECT only",
        data_type: "RailsQL::Introspection::InputValue",
        resolve: ->(args, child_query) {
          model.try :input_field_definitions
        }
      )

      # TODO: non nulls and lists
      field(:ofType,
        description: "NON_NULL and LIST only",
        data_type: "RailsQL::Introspection::Type",
        resolve: ->(args, child_query) {
          nil
        }
      )

      can :read, fields: [
        :kind,
        :name,
        :fields,
        :description,
        :fields,
        :interfaces,
        :possibleTypes,
        :enumValues,
        :inputFields,
        :ofType
      ]
    end
  end
end
