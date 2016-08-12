module RailsQL
  module Builder
    module Reducers
      class TypeKlassResolver

        # Recursively build and return an instance of `type_klass` and it's
        # children based on the builder, field definition and ctx.
        def visit_node(
          node:,
          parent_nodes:
        )
          return node if node.root? || node.fragment?

          node = node.shallow_clone_node

          parent_type_node = parent_nodes.reject do |parent|
            parent.directive? || parent.fragment?
          end.last

          # Resolve fields and args
          if node.name.present?
            node.field_definition = parent_type_node.field_definitions[node.name]
            if node.field_definition.blank?
              raise InvalidField, "invalid field #{child_node.name}"
            end
          # Resolve fields and args wrapped by modifiers
          elsif parent_type_node.modifier_type?
            node.type_klass = parent_node.of_type
          # Resolve directives
          else
            raise "unsupported node"
          end

          node
        end

      end
    end
  end
end
