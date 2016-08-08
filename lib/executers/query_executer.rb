module RailsQL
  class Executers
    class QueryExecuter < Executer

      def execute!
        recurse_into_child parent: nil, child: @root
        return self
      end

      private

      # Iterate depth first - from the scalar leaves to root type of the type
      # tree
      def recurse_into_child(parent:, child:)
        # binding.pry
        child.query = child.initial_query
        child_query_nodes_for(child).each do |grandchild_node|
          recurse_into_child grandchild_node
        end
        if child.query_lambda.present?
          puts "child.query_lambda.present? == true (for parent=#{parent}, child=#{child})"
          parent.query = parent.instance_exec(
            child.args,
            child.query,
            &child.query_lambda
          )
        end
      end

    end
  end
end
