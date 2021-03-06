module RailsQL
  class Type
    module KlassFactory
      def self.find(klass)
        raise "klass is required" if klass.nil?

        if (
          !klass.try(:type?) &&
          Scalar::Util.type_names.include?(klass.to_s.to_sym)
        )
          klass = RailsQL::Scalar.const_get klass.to_s
        end
        if [Symbol, String].include? klass.class
          klass_name = klass.to_s
          # eg. ![[ would be a non-nullable array of arrays of the klass
          modifier_suffix = klass_name.gsub(/[^\!\]]/, "")
          klass = klass_name.gsub(/[\!\[\]]/, "").classify.constantize
          # Wrap the klass in it's modifiers from the inside out
          modifier_suffix.each_char do |char|
            modifier_klass = Class.new char == "!" ? NonNullable : List
            modifier_klass.of_type = klass
            klass = modifier_klass
          end
        end
        unless klass.try(:type?)
          raise "#{klass} is not a valid Type"
        end
        return klass
      end
    end
  end
end
