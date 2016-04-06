module RailsQL
  module DataType
    class Primative
      attr_accessor :model
      alias_method :to_json, :model

      def query
        nil
      end

    end

    class String < Primative
    end

    class Integer < Primative
    end

    class Float < Primative
    end

    class Boolean < Primative
    end

    class JSON < Primative
    end

  end
end