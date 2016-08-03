module RailsQL
  module Scalar
    class Int  < RailsQL::Type
      kind :scalar
      type_name "Int"
      description <<~DESC
        The `Int` scalar type represents non-fractional signed whole numeric
        values. Int can represent values between -(2^53 - 1) and 2^53 - 1
        since represented in JSON as double-precision floating point numbers
        specified by
        [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
      DESC

      def parse_value!(value)
        if value.nil?
          nil
        elsif value.to_i.to_s == value.to_s
          value.to_i
        else
          raise ArgTypeError.new, "#{value} is not an int"
        end
      end
    end
  end
end
