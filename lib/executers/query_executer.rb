module RailsQL
  class Executers
    class QueryExecuter < Executer

      def execute!
        @root.query = @root.initial_query
        stack = child_nodes_for @root
        return self
      end

      private

      # Iterate depth first - from the scalar leaves to root type of the type
      # tree
      def recurse_into_child(parent:, child:)
        child_query_nodes_for(child).each do |grandchild_node|
          recurse_into_child grandchild_node
        end
        if child.query_lambda.present?
          parent.query = parent.instance_exec(
            child.args,
            parent.query,
            &child.query_lambda
          )
        end
      end

    end
  end
end