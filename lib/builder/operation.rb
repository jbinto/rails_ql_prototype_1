module RailsQL
  module Builder
    class Operation
      attr_accessor(
        :name,
        :operation_type,
        :variable_definitions,
        :root_node
      )

      def initialize
        @variable_definitions = {}
      end

    end
  end
end
