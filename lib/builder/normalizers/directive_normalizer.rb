# Inlines directives into child builders
module RailsQL
  module Builder
    module Normalizers
      class DirectiveNormalizer

        # Inlines the directives on fields inside this builder. Should be called
        # recursively on each builder/type_klass/field_definition.
        def normalize!(
          field_definition: nil,
          type_klass:,
          builder:
        )
          # TODO: pending directives dev time
          return builder
          # normalize directives (inlining)
          builder.child_builders.each do |child_builder|
            wrap_child_in_directives!(
              parent_builder: builder,
              child_builder: child_builder
            )
          end
        end

        private

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
        def wrap_child_in_directives!(parent_builder:, child_builder:)
          # Normalize directives by wrapping the child builder in it's
          # directive builder(s).
          directive_builder = child_builder.first_directive_builder
          if directive_builder.present?
            # wrap the field in it's directive chain
            child_builder.last_directive_builder.child_builders << child_builder
            # remove the directive builder from the field (to make
            # this method idempotent)
            child_builder.first_directive_builder = nil
            # replace the field with it's directive (now wrapping the child)
            index = builder.child_builders.index_of child_builder
            parent_builder.child_builders[index] = directive_builder
          end
        end

      end
    end
  end
end
