require_relative "./type_builder.rb"

module RailsQL
  module Builder
    class FragmentBuilder
      delegate(
        *(TypeBuilder.instance_methods - Object.methods),
        to: :type_builder
      )

      attr_reader :fragment_name, :type_builder

      def initialize(fragment_name: nil)
        @fragment_name = fragment_name
        @defined = false
      end

      def type_builder=(type_builder)
        if @defined
          raise(InvalidFragment,
            "Fragment #{@fragment_name} defined multiple times"
          )
        end
        @defined = true
        @type_builder=type_builder
      end

    end
  end
end
