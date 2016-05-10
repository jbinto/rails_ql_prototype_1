# used for introspection
# the model resolves to the schema data_type class

module RailsQL
  module DataType
    module Introspection
      class Schema < Base
        has_many(:types,
          data_type: "RailsQL::DataType::Introspection::Type",
          resolve: ->(args, child_query){
            self.class.all_type_klasses_in(model)
          }
        )

        def self.name
          "__Schema"
        end

        def self.all_type_klasses_in(klass)
          klass.field_definitions
            .values
            .map(&:data_type_klass)
            .uniq
            .map {|child_klass| [child_klass, all_type_klasses_in(child_klass)]}
            .concat([klass])
            .flatten
            .uniq
        end

        can :read, fields: [:types]
      end
    end
  end
end