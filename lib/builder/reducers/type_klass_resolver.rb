module RailsQL
  module Builder
    class TypeKlassResolver

      # Recursively build and return an instance of `type_klass` and it's
      # children based on the builder, field definition and ctx.
      def visit_node(
        node:,
        parent_nodes:
      )
        raise "node.ctx cannot be nil" if node.ctx.nil?
        return node if node.root?

        # Build ctx and opts to be passed to the `type_klass` constructor
        node = node.shallow_clone_node

        object_parent = parent_nodes.select do |parent|
          [:object, :input_object].include? parent.kind
        end.first

        # Fields and args
        if node.name.present?
          node.field_definition = object_parent.field_definitions[node.name]
          if node.field_definition.blank?
            raise InvalidField, "invalid field #{child_node.name}"
          end
        # Fields and args wrapped by modifiers
        elsif parent_nodes.last.modifier_type?
          node.type_klass = parent_node.of_type
        # Directives
        else
          raise "unsupported node"
        end

        node.child_nodes = node.child_nodes.map do |child_node|
          if [:object, :input_object].include? node.kind
          end

        end

      end

    end
  end
end
