module RailsQL
  module Builder
    class Operation
      attr_accessor(
        :name,
        :operation_type,
        :variable_definitions,
        :root_builder
      )

      def initialize
        @variable_definitions = {}
      end

    end
  end
end
