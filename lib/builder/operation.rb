module RailsQL
  module Builder
    class Operation
      attr_accessor(
        :name,
        :operation_type,
        :variable_builders,
        :root_builder
      )

      def initialize
        @variable_builders = {}
      end

    end
  end
end
