# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  module Introspection
    class Field  < RailsQL::Type
      type_name "__Field"

      description <<-eos
        Object and Interface types are described by a list of Fields, each of
        which has a name, potentially a list of arguments, and a return type.
      eos

      field :name, type: :String
      field :description, type: :String
      has_many(:args,
        type: "RailsQL::Introspection::InputValue",
        resolve: ->(args, child_query){
          model.args.input_field_definitions
        }
      )
      has_one(:type,
        type: "RailsQL::Introspection::Type",
        query: nil,
        resolve: ->(args, child_query){
          model.type_klass
        }
      )
      field :singular, type: :Boolean
      field(:isDeprecated,
        type: :Boolean,
        resolve: ->(args, child_query) {
          model.deprecated?
        }
      )
      field(:deprecationReason,
        type: :String,
        resolve: ->(args, child_query) {
          model.deprecation_reason
        }
      )

      can :read, fields: [
        :name,
        :description,
        :singular,
        :args,
        :type,
        :isDeprecated,
        :deprecationReason
      ]
    end
  end
end
