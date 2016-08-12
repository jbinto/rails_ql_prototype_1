module RailsQL
  class Type
    class List < Type

      anonymous true

      def self.of(modified_klass)
        subclass = Class.new List
        subclass.of_type = modified_klass
        subclass
      end

      def initialize(modified_type:, list_of_resolved_types: nil, **opts)
        @modified_type = modified_type
        @list = list_of_resolved_types
        super opts
      end

      def self.of_type=(of_type)
        @of_type = of_type
      end

      def self.of_type
        KlassFactory.find @of_type
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
        return @list.map &:as_json
      end

    end
  end
end
