module RailsQL
  module DataType
    module Kind
      def self.enum_values
        [
          :SCALAR,
          :OBJECT,
          :INTERFACE,
          :UNION,
          :ENUM,
          :INPUT_OBJECT,
          :LIST,
          :NON_NULL
        ]
      end

    end
  end
end
