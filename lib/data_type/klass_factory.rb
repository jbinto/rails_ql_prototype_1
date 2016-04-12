module RailsQL
  module DataType
    module KlassFactory
      def self.find(klass)
        if [Symbol, String].include? klass.class
          klass = klass.to_s.classify.constantize
        end
        if (
          !klass.try(:data_type?) &&
          Primative.data_type_names.include?(klass.to_s.to_sym)
        )
          klass = Primative.const_get klass.to_s
        end
        unless klass.try(:data_type?)
          raise "#{klass} is not a valid DataType"
        end
        return klass
      end
    end
  end
end
