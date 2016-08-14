module RailsQL
  class Type
    class List < Type
      kind :list
      anonymous true
      attr_accessor :modified_type, :list_of_resolved_types

      def self.of(modified_klass)
        subclass = Class.new List
        subclass.of_type = modified_klass
        subclass
      end

      def initialize(opts={})
        super opts
      end

      def self.of_type=(of_type)
        @of_type = of_type
      end

      def self.of_type
        KlassFactory.find @of_type
      end

      def self.type_name
        "[#{of_type.type_name}]"
      end

      def self.modifier_type?
        true
      end

      def query_tree_children
        [@modified_type]
      end

      def resolve_tree_children
        @list ||= (model || []).map do |singular_model|
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
        list = resolve_tree_children
        list.present? ? list.map(&:as_json) : nil
      end

    end
  end
end
