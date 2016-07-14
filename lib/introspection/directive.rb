# used for introspection
# the model resolves to the field_definition being introspected

module RailsQL
  class Type
    module Introspection
      class Directive  < RailsQL::Type
        type_name "__Directive"

        description <<-eos
        eos

        field(:name,
          data_type: :String,
          nullable: false
        )

        field(:description,
          data_type: :String
        )

        has_many(:locations,
          data_type: "RailsQL::Introspection::DirectiveLocation",
          nullable: false
        )

        has_many(:args,
          data_type: "RailsQL::Introspection::InputValue",
          nullable: false,
          resolve: ->(args, child_query){
            model.args.map{|k, v|
              {name: k}
            }
          }
        )

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
