# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  module DataType
    module Introspection
      class EnumValue < Base
        description <<-eos
          One possible value for a given Enum. Enum values are unique values,
          not a placeholder for a string or numeric value. However an Enum value
          is returned in a JSON response as a string.
        eos

        field(:name,
          data_type: :String,
          nullable: false,
        )

        field(:description,
          data_type: :String,
        )

        field(:isDeprecated,
          data_type: :Boolean,
          nullable: false,
        )

        field(:deprecationReason,
          data_type: :String,
        )

        def self.name
          "__EnumValue"
        end

        can :read, fields: [
          :name,
          :description,
          :isDeprecated,
          :deprecationReason
        ]
      end
    end
  end
end
