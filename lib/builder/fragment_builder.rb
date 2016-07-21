require_relative "./type_builder.rb"

module RailsQL
  module Builder
    class FragmentBuilder
      delegate(
        *(TypeBuilder.instance_methods - Object.methods),
        to: :type_builder
      )

      attr_reader :fragment_name
      attr_accessor :type_builder

      def initialize(fragment_name:)
        @fragment_name = fragment_name
        @defined = false
      end

      def define_fragment_once!
        if @defined
          raise(InvalidFragment,
            "Fragment #{@fragment_name} defined multiple times"
          )
        end
        @defined = true
      end
    end
  end
end
