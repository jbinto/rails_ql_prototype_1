module RailsQL
  class Executers
    class Executer

      def initialize(root:, operation:)
        @root = root
        @operation = operation
      end

      protected

      def child_nodes_for(parent)
        parent.fields.map do |k, child|
          {
            child: child,
            parent: parent
          }
        end
      end

    end
  end
end
