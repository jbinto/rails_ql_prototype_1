# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  module DataType
    module Introspection
      class InputValue < Base
        description(
          "Object and Interface types are described by a list of Fields, each of " +
          " which has a name, potentially a list of arguments, and a return type."
        )

        field(:name,
          data_type: :String,
          resolve: ->(args, child_query) {
            model[:name]
          }
        )
        field(:description,
          data_type: :String,
          resolve: ->(args, child_query) {
            nil # TODO
          }
        )
        field(:type,
          data_type: "RailsQL::DataType::Introspection::Type",
          nullable: true, # For now. Should be false.
          resolve: ->(args, child_query) {
            nil # TODO
          }
        )
        field(:defaultValue,
          data_type: :String,
          nullable: true,
          resolve: ->(args, child_query) {
            nil # TODO
          }
        )

        def self.name
          "__InputValue"
        end

        can :read, fields: [
          :name,
          :description,
          :type,
          :defaultValue
        ]
      end
    end
  end
end
