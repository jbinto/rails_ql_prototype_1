# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  module Introspection
    class InputValue  < RailsQL::Type
      type_name "__InputValue"

      description <<-eos
        Object and Interface types are described by a list of Fields, each of
        which has a name, potentially a list of arguments, and a return type.
      eos

      field(:name,
        type: :String,
        nullable: false
      )
      field(:description,
        type: :String
      )
      field(:type,
        type: "RailsQL::Introspection::Type",
        nullable: true, # For now. Should be false.
        resolve: ->(args, child_query) {
          nil # TODO
        }
      )
      field(:defaultValue,
        type: :String,
        nullable: true,
        resolve: ->(args, child_query) {
          model.default_value
        }
      )

      can :query, fields: [
        :name,
        :description,
        :type,
        :defaultValue
      ]
    end
  end
end
