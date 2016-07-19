module RailsQL
  module Scalar
    class ID  < RailsQL::Type
      kind :scalar
      type_name "ID"
      description <<-DESC.strip_heredoc
        The `ID` scalar type represents a unique identifier, often used to
        refetch an object or as key for a cache. The ID type appears in a JSON
        response as a String; however, it is not intended to be human-readable.
        When expected as an input type, any string (such as `"4"`) or integer
        (such as `4`) input value will be accepted as an ID.
      DESC

      def parse_value!(value)
        if value.nil? || value.is_a?(::String)
          return value
        else
          raise ArgTypeError.new, "#{value} is not a string"
        end
      end

    end
  end
end
