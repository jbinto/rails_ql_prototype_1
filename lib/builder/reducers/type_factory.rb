module RailsQL
  module Builder
    module Reducers
      class TypeFactory

        # Recursively build and return an instance of `type_klass` and it's
        # children based on the XXX TODO
        def visit_node(
          node:,
          parent_nodes:
        )
          # Skip the root, it's already instantiated
          return node if node.root?

          parent_ctx = parent_nodes.last.ctx

          raise "node.type_klass cannot be nil" if node.type_klass.nil?
          raise "node.ctx cannot be nil" if parent_ctx.nil?

          node = node.shallow_clone_node

          type = node.type_klass.new(
            ctx: parent_ctx.merge(node.field_definition.try(:child_ctx) || {}),
            root: node.root?,
            field_definition: node.field_definition,
            aliased_as: node.aliased_as || node.name
          )
          type.model = node.model
          node.type = type

          node
        end

        def end_visit_node(
          node:,
          parent_nodes:
        )
          child_types = node.child_nodes.map &:type
          if node.input? && node.is_a?(RailsQL::Type::List)
            node.list_of_resolved_types = child_types
          end
          if node.modifier_type?
            node.modified_type = child_types.first
          elsif node.directive?
            raise "TODO: directives"
            # node.args_type = node.args_node.type
            # node.modified_type = node.child_nodes.reject{|n| n.input?}.map &:type
          elsif node.union?
            raise "TODO: unions"
          else
            # XXX: can we be more explicit with this `else` block here?
            # e.g. currently it reads "when it is not a modifier, directive, or union"
            # (which implicitly means "if it is a fragment, field, or object type")
            node.field_types = node.find_field_nodes_for_type.map &:type
          end
        end

      end
    end
  end
end
