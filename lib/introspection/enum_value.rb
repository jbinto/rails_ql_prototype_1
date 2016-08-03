# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  module Introspection
    class EnumValue  < RailsQL::Type
      type_name "__EnumValue"

      description <<~eos
        One possible value for a given Enum. Enum values are unique values,
        not a placeholder for a string or numeric value. However an Enum value
        is returned in a JSON response as a string.
      eos

      field(:name,
        type: :String,
        nullable: false
      )

      field(:description,
        type: :String,
      )

      field(:isDeprecated,
        type: :Boolean,
        nullable: false,
        resolve: ->(args, child_query){
          model.is_deprecated
        }
      )

      field(:deprecationReason,
        type: :String,
        resolve: ->(args, child_query){
          model.deprecation_reason
        }
      )

      can :query, fields: [
        :name,
        :description,
        :isDeprecated,
        :deprecationReason
      ]
    end
  end
end
