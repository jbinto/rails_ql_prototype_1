module RailsQL
  module Builder
    class BuilderTreeVisitor

      def initialize(reducers:)
        @reducers = reducers
      end

      # https://en.wikipedia.org/wiki/Fold_(higher-order_function)#Linear_vs._tree-like_folds
      def tree_like_fold(
        field_definition: nil,
        type_klass:,
        node:,
        parent_nodes: []
      )
        # Each reducer returns a node which is used as the node by the next
        # reducer
        node = @reducers.reduce(node) do |reducer, opts|
          reducer.visit_node(
            field_definitions: field_definitions,
            type_klass: type_klass,
            node: node
          )
        end

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

        return modified_node
      end

    end
  end
end
