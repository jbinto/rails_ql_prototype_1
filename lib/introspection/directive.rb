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
          type: :String,
          nullable: false
        )

        field(:description,
          type: :String
        )

        field(:locations,
          type: "[RailsQL::Introspection::DirectiveLocation]",
          nullable: false
        )

        field(:args,
          type: "[RailsQL::Introspection::InputValue]",
          nullable: false,
          resolve: ->(args, child_query){
            model.args.map{|k, v|
              {name: k}
            }
          }
        )

        can :query, fields: [
          :name,
          :description,
          :locations,
          :args
        ]
      end
    end
  end
end
