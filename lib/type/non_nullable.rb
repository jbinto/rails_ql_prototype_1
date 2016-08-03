module RailsQL
  class Type
    class NonNullable
      attr_reader :model
      attr_accessor :type

      delegate(
        :unauthorized_fields_and_args_for,
        :build_query!,
        :append_to_parent_query!,
        :as_json,
        to: :type
      )

      def initialize(opts={})
        @opts = opts
      end

      def model=(value)
        raise_cannot_be_nil! if value.nil?
        type.model = value
      end

      def omit_from_json?
        false
      end

      def root?
        false
      end

      def as_json
        json = type.as_json
        raise_cannot_be_nil! if json.nil?
        return json
      end

      def raise_cannot_be_nil!
        raise NullField, <<-ERROR.strip_heredoc.gsub("\n", " ").strip
          NonNullable Type #{type.class.type_definition.name}!
          on field @name cannot be null
        ERROR
      end

    end
  end
end
