# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  module DataType
    module Introspection
      class Field < Base
        description(
          "Object and Interface types are described by a list of Fields, each of " +
          " which has a name, potentially a list of arguments, and a return type."
        )

        field :name, data_type: :String
        field :args, data_type: :JSON, resolve: ->(args, child_query){field_args}
        field :description, data_type: :String
        field :deprecated, data_type: :Boolean
        field(:type,
          data_type: "RailsQL::DataType::IntrospectType",
          singular: true,
          query: nil,
          resolve: ->(args, child_query){model.data_type_klass}
        )

        def self.name
          "__Field"
        end

        def name
          # ap model
          # klass_name = field_definition.data_type_klass.to_s.gsub(
          #   "RailsQL::DataType::", ""
          # ).gsub(
          #   "Primative::", ""
          # )
          model.name.to_s
        end

        def field_args
          model.required_args.merge(
            model.optional_args
          ).stringify_keys
        end

        can :read, fields: [:name, :args, :type, :description, :deprecated]
      end
    end
  end
end
