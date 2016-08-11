# Normalizes fragment builders and unions of fragment builders into
# types builders
module RailsQL
  module Builder
    module Reducers
      class CircularReferenceChecker

        # Throws an exception if the fragment is a circular reference
        #
        # Should be called recursively on each builder/type_klass/
        # field_definition.
        #
        # Examples
        #
        # This is GOOD (no circular references)
        # ```
        #   query { ...fragA }
        #   fragment on fragA {name}
        # ```
        #
        # This is BAD (circular reference: fragA includes fragA)
        # ```
        #   query { ...fragA }
        #   fragment on fragA {...fragA}
        # ```
        #
        # This is BAD (circular reference: fragA includes fragB includes fragA)
        # ```
        #   query { ...fragA }
        #   fragment on fragA {...fragB}
        #   fragment on fragB {...fragA}
        # ```
        #
        def visit_node(
          field_definition: nil,
          type_klass:,
          node:
          parent_nodes:
        )
          is_circular_reference = parent_nodes.any? do |parent_node|
            parent_node.annotation == node.annotation
          end
          if is_circular_reference
            raise InvalidFragment, <<-ERROR.strip_heredoc.gsub("\n", " ").strip
              circular fragment reference in #{node.name}
            ERROR
          end

          node
        end

      end
    end
  end
end
