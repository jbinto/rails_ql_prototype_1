module RailsQL
  module Builder
    class BuilderTreeVisitor

      def initialize(reducers:)
        @reducers = reducers
      end

      # https://en.wikipedia.org/wiki/Fold_(higher-order_function)#Linear_vs._tree-like_folds
      def tree_like_fold(
        field_definition: nil,
        node:,
        parent_nodes: []
      )

        # Each reducer returns a node which is used as the node by the next
        # reducer
        node = run_reducers_for(:visit_node
          field_definition: field_definition,
          node: node,
          parent_nodes: parent_nodes
        )

        # Copy the node to make sure we're not modifying the original
        # (for the scenario where all the reducers returned the original node)
        node = node.shallow_clone_node

        # recurse into children
        node.child_nodes = node
          .child_nodes
          .map do |child_node|
            child_field_definition =
              if type_klass.field_definitions.present?
                type_klass.field_definitions[child_builder.name]
              else
                nil
              end
            # recurse
            tree_like_fold(
              field_definition: child_field_definition,
              type_klass: child_field_definition.type_klass,
              node: child_node,
              parent_nodes: parent_nodes + [node]
            )
          end

        node = run_reducers_for(:end_visit_node,
          field_definition: field_definition,
          node: node,
          parent_nodes: parent_nodes
        )

        node
      end

      private

      def run_reducers_for(method_sym)
        # Each reducer returns a node which is used as the node by the next
        # reducer
        @reducers.each do |reducer|
          if reducer.respond_to? method_sym
            node = reducer.send(method_sym
              field_definitions: field_definitions,
              type_klass: type_klass,
              node: node
            )
          end
        end
      rescue Exception => e
        name = field_definition.try(:name) || type_klass.type_name
        # Args
        if !parent_nodes.any?(&:input?) && node.input?
          name = "#{name} args"
        end
        msg = <<-ERROR.strip_heredoc.gsub("\n", " ").strip
           #{e.message} on #{name}
        ERROR
        raise e, msg, e.backtrace
      end

    end
  end
end
