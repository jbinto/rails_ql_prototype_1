module RailsQL
  module DataType
    module Primative
      def self.data_type_names
        Primative.constants.select do |c|
          Primative.const_get(c).is_a? Class
        end
      end

      class Base
        attr_accessor :model
        alias_method :as_json, :model

        def build_query!
          nil
        end

        def query
          nil
        end

        def self.data_type?
          true
        end
      end

      class String < Base
      end

      class Integer < Base
      end

      class Float < Base
      end

      class Boolean < Base
      end

      class JSON < Base
      end

    end
  end
end