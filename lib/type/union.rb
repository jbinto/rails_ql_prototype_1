require_relative "./type.rb"

module RailsQL
  class Union < RailsQL::Type
    type_name "Union"
    description <<-eos
      GraphQL Unions represent an object that could be one of a list of
      GraphQL Object types, but provides for no guaranteed fields
      between those types. They also differ from interfaces in that Object
      types declare what interfaces they implement, but are not aware of what
      unions contain them.

      With interfaces and objects, only those fields defined on the type can
      be queried directly; to query other fields on an interface, typed
      fragments must be used. This is the same as for unions, but unions do
      not define any fields, so no fields may be queried on this type
      without the use of typed fragments.
    eos

    def as_json
      json = super

      return json[@resolved_type]
    end

    # unions(
    #   {name: "sword", type: "SwordType, model_klass: "Sword"},
    #   {name: "cross_bow", type: "CrossBowType, model_klass: "CrossBow"}
    # )
    class << self
      def unions(*union_definitions)
        return nil if union_definitions.blank?

        union_definitions = union_definitions.map &:symbolize_keys!

        union_definitions.each do |union_definition|
          field(union_definition[:name],
            union_definition.slice(:type, :model_klass).merge(
              union: true,
              nullable: true,
              singular: true,
              resolve: ->(args, child_query){
                model_klass =
                  if union_definition[:model_klass].kind_of? Proc
                    self.instance_exec(
                      &union_definition[:model_klass]
                    ).to_s.constantize
                    # union_definition[:model_klass].call.to_s.constantize
                  else
                    union_definition[:model_klass].to_s.constantize
                  end
                if model.kind_of? model_klass
                  @resolved_type = union_definition[:name]
                  model
                else
                  nil
                end
              }
            )
          )
        end
      end
    end
  end
end