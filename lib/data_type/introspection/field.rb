# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  module DataType
    module Introspection
      class Field < Base
        name "__Field"

        description <<-eos
          Object and Interface types are described by a list of Fields, each of
          which has a name, potentially a list of arguments, and a return type.
        eos

        field :name, data_type: :String
        field :description, data_type: :String
        has_many(:args,
          data_type: "RailsQL::DataType::Introspection::InputValue",
          resolve: ->(args, child_query){
            model.args.map{|k, v|
              {name: k}
            }
          }
        )
        field(:type,
          data_type: "RailsQL::DataType::Introspection::Type",
          singular: true,
          query: nil,
          resolve: ->(args, child_query){
            model.data_type_klass
          }
        )
        field(:isDeprecated,
          data_type: :Boolean,
          resolve: ->(args, child_query) {
            model.deprecated?
          }
        )
        field(:deprecationReason,
          data_type: :String,
          resolve: ->(args, child_query) {
            model.deprecation_reason
          }
        )

        can :read, fields: [
          :name,
          :description,
          :args,
          :type,
          :isDeprecated,
          :deprecationReason
        ]
      end
    end
  end
end
