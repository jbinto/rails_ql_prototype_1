module RailsQL
  class Type
    class NonNullable < Type
      kind :non_null
      anonymous true

      def initialize(opts={})
        @modified_type = opts[:modified_type]
        super opts
      end

      def self.of_type=(of_type)
        @of_type = of_type
      end

      def self.of_type
        KlassFactory.find @of_type
      end

      def self.modifier_type?
        true
      end

      def query_tree_children
        [@modified_type]
      end

      def resolve_tree_children
        [@modified_type]
      end

      def model=(value)
        raise_cannot_be_nil! if value.nil?
        type.model = value
      end

      def as_json
        json = @modified_type.as_json
        raise_cannot_be_nil! if json.nil?
        return json
      end

      def can?(action, field_name)
        field_name == nil
      end

      private

      def raise_cannot_be_nil!
        raise NullField, <<-ERROR.strip_heredoc.gsub("\n", " ").strip
          NonNullable Type #{type.class.type_definition.name}!
          on field @name cannot be null
        ERROR
      end

    end
  end
end
