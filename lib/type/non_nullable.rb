module RailsQL
  class Type
    class NonNullable < Type
      def initialize(opts={})
        @child_type = opts[:child_type]
        super opts
      end

      def query_tree_children
        [@child_type]
      end

      def resolve_tree_children
        [@child_type]
      end

      def model=(value)
        raise_cannot_be_nil! if value.nil?
        type.model = value
      end

      def as_json
        json = @child_type.as_json
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
