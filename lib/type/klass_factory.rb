module RailsQL
  class Type
    module KlassFactory
      def self.find(klass)
        if (
          !klass.try(:type?) &&
          Primative.type_names.include?(klass.to_s.to_sym)
        )
          klass = Primative.const_get klass.to_s
        end
        if [Symbol, String].include? klass.class
          klass = klass.to_s.classify.constantize
        end
        unless klass.try(:type?)
          raise "#{klass} is not a valid Type"
        end
        return klass
      end
    end
  end
end
