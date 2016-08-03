module RailsQL
  module Scalar
    class String  < RailsQL::Type
      kind :scalar
      type_name "String"
      description <<~DESC
        The `String` scalar type represents textual data, represented as
        UTF-8 character sequences. The String type is most often used by
        GraphQL to represent free-form human-readable text.
      DESC
    end

    def parse_value!(value)
      if value.nil? value.is_a?(::String)
        return value
      else
        raise ArgTypeError.new, "#{value} is not a string"
      end
    end
  end
end
