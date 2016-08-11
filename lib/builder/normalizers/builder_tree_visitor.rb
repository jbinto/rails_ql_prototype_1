module RailsQL
  module Builder
    module Normalizers
      class BuilderTreeVisitor

        # https://en.wikipedia.org/wiki/Fold_(higher-order_function)#Linear_vs._tree-like_folds
        def tree_like_fold(
          field_definition: nil,
          type_klass:,
          builder:
        )
          # The reducer must return a mutable clone of the builder for each
          # node in the tree
          builder = yield(
            field_definition: field_definition,
            type_klass: type_klass,
            builder: builder.shallow_mutable_clone
          )
          # recurse into children
          builder.child_builders = builder.child_builders.map do |child_builder|
            child_field_definition =
              if type_klass.field_definitions.present?
                type_klass.field_definitions[child_builder.name]
              else
                nil
              end
            child_node = {
              field_definition: child_field_definition,
              type_klass: child_field_definition.type_klass,
              builder: child_builder
            }
            tree_like_fold child_node
          end

        end

      end
    end
  end
end
