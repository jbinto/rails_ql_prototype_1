module RailsQL
  class Type
    class List < Type

      def initialize(opts={})
        @of_type = opts[:prototype_type].class
        super opts
      end

      def resolve_child_types!
        dup_fields_for_model!
        # Top to bottom recursion
        @fields.values.each &:resolve_child_types!
      end

      def as_json
        return @fields.map &:as_json
      end

      private

      def dup_fields_for_model!(models)
        @fields = model.map do |singular_model|
          field = prototype_field.deep_dup
          # field.type = prototype_field.type.deep_dup
          # field.type.fields = prototype_field.type.fields.deep_dup
          field.parent_type = self
          field.model = singular_model
          field
        end
      end

    end
  end
end
