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
          return node if node.root?

          node = node.shallow_clone_node

          # Find our closest concrete type parent (e.g. no fragments, directives)
          parent_type_node = parent_nodes.reject do |parent|
            parent.directive? || parent.fragment?
          end.last

          # Note: unions should have a seperate resolver that collects and moves
          # fragment nodes under nodes for each unioned type
          # fragment_on_unioned_type = (
          #   node.fragment? &&
          #   parent_type_node.union? &&
          #   fragment.of_type != parent_type_node.type_name
          # )

          # Assign the unioned type klass to fragments on unions
          # if fragment_on_unioned_type
          #   raise "TODO: unions"
          # Skip non-union fragments
          if node.fragment?
            return node
          elsif node.input? && !parent_nodes.any?(&:input?)
            # resolve arg objects/annonomous input objects
            node.type_klass = parent_type_node.args_type_klass
          elsif node.field_or_input_field?
            # Resolve fields and args
            node.field_definition = parent_type_node
              .child_field_definitions[node.name]
            # If query requested field that does not exist
            # (e.g. not present in parent FieldDefinitionCollection)
            if node.field_definition.nil?
              raise InvalidField, "invalid field #{child_node.name}"
            end
          elsif parent_type_node.modifier_type?
            # Resolve fields and args wrapped by modifiers
            node.type_klass = parent_type_node.of_type
          else
            # TODO: Resolve directives
            raise "unsupported node"
          end

          node
        end

      end
    end
  end
end
