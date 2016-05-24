# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  module DataType
    module Introspection
      class Directive < Base
        description <<-eos
        eos

        field(:name,
          data_type: :String,
          nullable: false,
        )

        field(:description,
          data_type: :String,
        )

        has_many(:locations,
          data_type: :Boolean,
          nullable: false,
        )

        has_many(:args,
          data_type: "RailsQL::DataType::Introspection::InputValue",
          resolve: ->(args, child_query){
            model.args.map{|k, v|
              {name: k}
            }
          }
        )

        def self.name
          "__Directive"
        end

        can :read, fields: [
          :name,
          :description,
          :locations,
          :args
        ]
      end
    end
  end
end
