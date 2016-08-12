module RailsQL
  module Builder
    class Annotation
      attr_accessor(
        # The name of the field or nil for anonomous input objects and roots
        :name,
        :args_node,
        :aliased_as,
        :directive_name,
        :name_for_error_messages,
        :first_directive_node,
        :unioned_type_klass,
        :root,
        # is_input is true if this type is used as an argument to a field
        # (input).
        # is_input is false if this type is used as a field (output).
        :is_input,
        :is_anonymous_input_object,
        :variables,
        :model,
        :fragment_name
        :inline_fragment
      )

      attr_reader(
        :fragment_defined_on
      )

      alias_method :input?, :is_input
      alias_method :root?, :root
      alias_method :defined_fragment?, :defined_fragment
      alias_method :inline_fragment?, :inline_fragment

      def fragment_defined_on=(val)
        if @defined_fragment
          raise(InvalidFragment,
            "Fragment #{@fragment_name} defined multiple times"
          )
        end
        @defined_fragment = true
        @fragment_defined_on = val
      end

      def fragment?
        fragment_name || inline_fragment
      end

      def directive?
        directive_name.present?
      end

    end
  end
end
