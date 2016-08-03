module RailsQL
  class Executers
    class Executer

      def initialize(root:, operation_type:)
        @root = root
        @operation_type = operation_type
      end

      protected

      def child_query_nodes_for(parent)
        parent.query_tree_children.map do |child|
          {
            child: child,
            parent: parent
          }
        end
      end

      def child_resolve_nodes_for(parent)
        parent.resolve_tree_children.map do |child|
          {
            child: child,
            parent: parent
          }
        end
      end

    end
  end
end
