module RailsQL
  module Scalar
    module Util
      def self.type_names
        Scalar.constants.select do |c|
          Scalar.const_get(c).is_a? Class
        end
      end
    end
  end
end
