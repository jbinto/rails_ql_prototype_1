require 'active_support/concern'

module RailsQL
  module DataType
    module Introspection
      extend ActiveSupport::Concern

      included do
        field(:__type,
          required_args: {name: "StringValue"},
          data_type: "RailsQL::DataType::Introspection::Type",
          singular: true,
          resolve: ->(args, child_query){
            Introspection::__Schema.all_type_klasses_in(model)
              .select {|data_type| data_type.name == args[:name]}
              .first
          }
        )

        field(:__schema,
          data_type: "RailsQL::DataType::Introspection::Schema",
          singular: true,
          resolve: ->(args, child_query){self.class}
        )

        can :read, fields: [:__type, :__schema]
      end

    end
  end
end
