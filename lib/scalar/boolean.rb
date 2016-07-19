module RailsQL
  module Scalar
    class Boolean  < RailsQL::Type
      kind :scalar
      type_name "Boolean"
      description <<-DESC.strip_heredoc
        The `Boolean` scalar type represents `true` or `false`.
      DESC

      def parse_value!(value)
        if [true, false, nil].include value
          return value
        else
          raise ArgTypeError.new, "#{value} is not a boolean"
        end
      end
    end
  end
end
