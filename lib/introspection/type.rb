# used for introspection
# the model resolves to the type class being introspected

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
        type: "RailsQL::Introspection::TypeKind",
        nullable: false,
        resolve: ->(args, child_query) {
          model.type_definition.kind.to_s.upcase.to_sym
        }
      )

      field(:name,
        type: :String,
        resolve: ->(args, child_query) {
          model.type_definition.name
        }
      )

      field(:description,
        type: :String,
        resolve: ->(args, child_query) {
          model.type_definition.description
        }
      )

      field(:fields,
        description: "OBJECT and INTERFACE only",
        optional_args: {include_deprecated: {type: "Boolean"}},
        type: "[RailsQL::Introspection::Field]",
        resolve: ->(args, child_query){
          definitions = model.field_definitions
          if args[:include_deprecated] == false
            definitions = definitions.reject &:deprecated?
          end
          definitions.values
        }
      )

      # TODO: interfaces
      field(:interfaces,
        description: "OBJECT only",
        type: "[RailsQL::Introspection::Type]",
        resolve: ->(args, child_query) {
          []
        }
      )


      # TODO: interfaces and unions
      field(:possibleTypes,
        description: "INTERFACE and UNION only",
        type: "[RailsQL::Introspection::Type]",
        resolve: ->(args, child_query) {
          []
        }
      )

      # TODO: enums
      field(:enumValues,
        description: "ENUM only",
        type: "[RailsQL::Introspection::EnumValue]",
        resolve: ->(args, child_query) {
          model.type_definition.enum_values.values
        }
      )

      field(:inputFields,
        description: "INPUT_OBJECT only",
        type: "[RailsQL::Introspection::InputValue]",
        resolve: ->(args, child_query) {
          model.try :input_field_definitions
        }
      )

      # TODO: non nulls and lists
      field(:ofType,
        description: "NON_NULL and LIST only",
        type: "RailsQL::Introspection::Type",
        resolve: ->(args, child_query) {
          model.try :of_type
        }
      )

      can :query, fields: [
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
