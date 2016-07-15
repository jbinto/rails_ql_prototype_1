require 'active_support/concern'

module RailsQL
  class Type
    module Introspection
      extend ActiveSupport::Concern

      included do
        field(:__type,
          required_args: {name: "StringValue"},
          type: "RailsQL::Introspection::Type",
          singular: true,
          resolve: ->(args, child_query){
            Introspection::Schema.all_type_klasses_in(self.class)
              .select {|type| type.name == args[:name]}
              .first
          }
        )

        field(:__schema,
          type: "RailsQL::Introspection::Schema",
          singular: true,
          resolve: ->(args, child_query){self.class}
        )

        can :read, fields: [:__type, :__schema]
      end

    end
  end
end
