# used for introspection
# the model resolves to the schema data_type class

module RailsQL
  module DataType
    module Introspection
      class Schema < Base
        field(:queryType,
          data_type: "RailsQL::DataType::Introspection::Type",
          resolve: ->(args, child_query){
            model
          }
        )

        has_many(:types,
          data_type: "RailsQL::DataType::Introspection::Type",
          resolve: ->(args, child_query){
            self.class.all_type_klasses_in(model)
          }
        )

        def self.name
          "__Schema"
        end

        def self.all_type_klasses_in(klass, exclude = [])
          child_klasses = klass.field_definitions
            .values
            .map(&:data_type_klass)
            .uniq
            .reject{|child_klass| exclude.include? child_klass}
          all_known_klasses = child_klasses + exclude
          child_klasses
            .map {|child_klass|
              all_type_klasses_in(child_klass, all_known_klasses)
            }
            .concat([klass])
            .flatten
            .uniq
        end

        can :read, fields: [:queryType, :types]
      end
    end
  end
end
