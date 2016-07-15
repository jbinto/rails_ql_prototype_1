module RailsQL
  module Scalar
    class Float  < RailsQL::Type
      kind :scalar
      name "Float"
      description <<-DESC.strip_heredoc
        The `Float` scalar type represents signed double-precision
        fractional values as specified by
        [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).
      DESC

      def parse_value!(value)
        if value.nil?
          nil
        elsif value.to_f.to_s == value.to_s
          value.to_f
        else
          raise ArgTypeError.new, "#{value} is not a float"
        end
      end
    end
  end
end
