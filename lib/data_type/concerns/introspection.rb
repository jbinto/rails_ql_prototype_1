require 'active_support/concern'

module RailsQL
  module DataType
    module Introspection
      extend ActiveSupport::Concern

      included do
        field(:__type,
          required_args: {name: "StringValue"},
          data_type: "RailsQL::DataType::IntrospectType",
          singular: true,
          resolve: ->(args, child_query){__type_resolve(args)}
        )

        field(:__schema,
          data_type: "RailsQL::DataType::IntrospectSchema",
          singular: true,
          resolve: ->(args, child_query){self.class}
        )

        can :read, fields: [:__type, :__schema]
      end

      def __type_resolve(args)
        self.class.field_definitions.select do |name, field_definition|
          field_definition.data_type.to_s == args[:name]
        end.values.first.try :data_type_klass
      end

      module ClassMethods
      end

    end
  end
end
