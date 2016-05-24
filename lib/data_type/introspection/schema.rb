# used for introspection
# the model resolves to the schema data_type class

module RailsQL
  module DataType
    module Introspection
      class Schema < Base
        name "__Schema"
        description <<-eos
          A GraphQL Schema defines the capabilities of a GraphQL server. It
          exposes all available types and directives on the server, as well as
          the entry points for query and mutation operations.
        eos

        has_many(:types,
          description: <<-eos,
            A list of all types supported by this server.
          eos
          data_type: "RailsQL::DataType::Introspection::Type",
          resolve: ->(args, child_query){
            self.class.all_type_klasses_in(model)
          }
        )

        field(:queryType,
          description: <<-eos,
            The type that query operations will be rooted at.
          eos
          data_type: "RailsQL::DataType::Introspection::Type",
          resolve: ->(args, child_query){
            model
          }
        )

        # TODO: mutations
        field(:mutationType,
          description: <<-eos,
            If this server supports mutation, the type that mutation operations
            will be rooted at.
          eos
          data_type: "RailsQL::DataType::Introspection::Type",
          resolve: ->(args, child_query){
            nil
          }
        )

        # TODO: directives
        field(:directives,
          description: <<-eos,
            A list of all directives supported by this server.
          eos
          data_type: "RailsQL::DataType::Introspection::Directive",
          singular: false,
          resolve: ->(args, child_query){
            []
          }
        )

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

        can :read, fields: [
          :types,
          :queryType,
          :mutationType,
          :directives
        ]
      end
    end
  end
end
