require_relative "./type_builder.rb"

module RailsQL
  module Builder
    class FragmentBuilder
      delegate(
        *(TypeBuilder.instance_methods - Object.methods),
        to: :type_builder
      )

      attr_reader :fragment_name, :fragment_defined_on, :type_builder

      def initialize(fragment_name: nil, inline: false)
        if !inline && fragment_name.blank?
          raise "Fragment name must not be blank"
        end
        @fragment_name = fragment_name
        @inline = inline
        @defined = false
        @directive_builders = []
      end

      def type_builder=(type_builder)
        if allow_redefinition == false && @defined
          raise(InvalidFragment,
            "Fragment #{@fragment_name} defined multiple times"
          )
        end
        @defined = true
        @type_builder=type_builder
      end

      def add_directive_builder!(directive_builder)
        @directive_builders << directive_builder
      end

      def allow_redefinition
        @inline
      end

    end
  end
end
