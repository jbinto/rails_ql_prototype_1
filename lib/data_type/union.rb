require "active_model/callbacks"
require_relative "./field_definition"

module RailsQL
  module DataType
    class Union < Base
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

    	def resolve_child_data_types!
    	end

    	def as_json
    	end
    end
  end
end