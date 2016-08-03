module RailsQL
  class Type
    class List < Type

      def initialize(opts={})
        @prototype_type = opts[:prototype_type]
        super opts
      end

      def query_tree_children
        [@prototype_type]
      end

      def resolve_tree_children
        @list_values ||= model.map do |singular_model|
          field = prototype_field.deep_dup
          # field.type = prototype_field.type.deep_dup
          # field.type.fields = prototype_field.type.fields.deep_dup
          field.parent_type = self
          field.model = singular_model
          field
        end
      end

      def can?(action, field_name)
        field_name == nil
      end

      def as_json
        return @list_values.map &:as_json
      end

    end
  end
end
