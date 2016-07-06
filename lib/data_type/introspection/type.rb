# used for introspection
# the model resolves to the data_type class being introspected

module RailsQL
  module DataType
    module Introspection
      class Type < Base
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
          data_type: "RailsQL::DataType::Introspection::TypeKind",
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
          optional_args: {include_deprecated: {type: "Boolean"}},
          data_type: "RailsQL::DataType::Introspection::Field",
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
          data_type: "RailsQL::DataType::Introspection::Type",
          resolve: ->(args, child_query) {
            []
          }
        )


        # TODO: interfaces and unions
        has_many(:possibleTypes,
          data_type: "RailsQL::DataType::Introspection::Type",
          resolve: ->(args, child_query) {
            []
          }
        )

        # TODO: enums
        has_many(:enumValues,
          data_type: "RailsQL::DataType::Introspection::EnumValue",
          resolve: ->(args, child_query) {
            model.type_definition.enum_values.values
          }
        )

        # TODO: input objects
        has_many(:inputFields,
          data_type: "RailsQL::DataType::Introspection::InputValue",
          resolve: ->(args, child_query) {
            []
          }
        )

        # TODO: non nulls and lists
        field(:ofType,
          data_type: "RailsQL::DataType::Introspection::Type",
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
end
