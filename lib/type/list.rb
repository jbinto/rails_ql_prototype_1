module RailsQL
  class Type
    class List < Type

      attr_accessor :of_type

      def initialize(opts={})
        @modified_type = opts[:modified_type]
        super opts
      end

      def query_tree_children
        [@modified_type]
      end

      def resolve_tree_children
        @list ||= model.map do |singular_model|
          type = @modified_type.deep_dup
          # type.type = @modified_type.type.deep_dup
          # type.type.fields = @modified_type.type.fields.deep_dup
          type.model = singular_model
          type
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
