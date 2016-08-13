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
          raise "node.type cannot be nil" if node.type.nil?
          raise "node.ctx cannot be nil" if node.ctx.nil?
          # Skip the root, it's already instantiated
          return node if node.root?

          # XXX: shouldn't we shallow clone the node here?
          # eg.
          # node = node.shallow_clone_node

          parent_ctx = parent_nodes.last.ctx

          # XXX type_klass is not defined
          type = type_klass.new(
            # XXX field_definition is not defined
            ctx: parent_ctx.merge(field_definition.try(:child_ctx) || {}),
            root: node.root?,
            field_definition: field_definition,
            aliased_as: node.aliased_as || node.name
          )
          # XXX model is not defined
          type.model = model
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
