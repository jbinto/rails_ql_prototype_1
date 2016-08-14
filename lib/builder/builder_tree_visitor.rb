module RailsQL
  module Builder
    class BuilderTreeVisitor

      def initialize(reducers:)
        @reducers = reducers
      end

      # https://en.wikipedia.org/wiki/Fold_(higher-order_function)#Linear_vs._tree-like_folds
      def tree_like_fold(
        node:,
        parent_nodes: []
      )

        # Each reducer returns a node which is used as the node by the next
        # reducer
        node = run_reducers_for(:visit_node,
          node: node,
          parent_nodes: parent_nodes
        )

        # Copy the node to make sure we're not modifying the original
        # (for the scenario where all the reducers returned the original node)
        node = node.shallow_clone_node

        # recurse into children
        node.child_nodes = node.child_nodes.map do |child_node|
          tree_like_fold(
            node: child_node,
            parent_nodes: parent_nodes + [node]
          )
        end

        node = run_reducers_for(:end_visit_node,
          node: node,
          parent_nodes: parent_nodes
        )

        node
      end

      private

      def run_reducers_for(method_sym, node: , parent_nodes:)
        # Each reducer returns a node which is used as the node by the next
        # reducer
        reducer_run_order =
          if method_sym == :visit_node
            @reducers
          else
            @reducers.reverse
          end
        reducer_run_order.each do |reducer|
          if reducer.respond_to? method_sym
            node = reducer.send(method_sym,
              node: node,
              parent_nodes: parent_nodes
            )
          end
        end

        node

      rescue Exception => e
        name = node.aliased_as
        name ||= "root" if node.root?
        # Args
        if !parent_nodes.any?(&:input?) && node.input?
          name = "#{parent_nodes.last.aliased_as} args"
        end
        msg = <<-ERROR.strip_heredoc.gsub("\n", " ").strip
           #{e.message} on #{name}
        ERROR
        raise e, msg, e.backtrace
      end

    end
  end
end
