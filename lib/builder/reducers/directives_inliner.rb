# Inlines directives into child builders
module RailsQL
  module Builder
    module Reducers
      class DirectivesInliner

        # Inlines the directives on fields inside this builder. Should be called
        # recursively on each builder/type_klass/field_definition.
        #
        # Example
        #
        # For this query:
        #   hero {
        #     fiends @skip @include @whatever {
        #       name
        #     }
        #   }
        #
        # Changes this:
        #   hero -> friends -> names
        #            #first_directive = @skip -> @include -> @whatever
        #
        # to this:
        #   hero -> @skip -> @include -> @whatever -> friends -> name
        def visit_node(
          node:,
          parent_nodes:
        )
          original_node = node

          # Normalize directives by wrapping the child builder in it's
          # directive builder(s).
          directive_node = child_builder.first_directive_node
          return original_node if directive_node.blank?

          # wrap the node in a copy of it's directive chain
          modified_node = directive_node.duplicate_tree
          modified_node.find_leaf_nodes.first.child_nodes = [original_node]
          modified_node
        end

      end
    end
  end
end
