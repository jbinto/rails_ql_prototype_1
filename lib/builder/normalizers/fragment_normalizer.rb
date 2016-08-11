# Normalizes fragment builders and unions of fragment builders into
# types builders
module RailsQL
  module Builder
    module Normalizers
      class FragmentNormalizer

        # Injects fields on the fragment spreads on in this builder into the
        # builder itself.
        # Should be called recursively on each builder/type_klass/
        # field_definition.
        def normalize!(
          field_definition: nil,
          type_klass:,
          builder:
        )
          builder.fragment_builders.each do |fragment_builder|
            validate_fragment_builder!(
              type_klass: builder.type_klass,
              builder: fragment_builder
            )
            if (
              type_klass.is_a?(RailsQL::Union) &&
              fragment_builder.defined_on != type_klass.type_name
            )
              raise "Unions are not currently supported"
              # builder.child_builders << fragment_builder
            else
              # TODO: this will not work for fragment spread with directives.
              # for directives on spreads and fragment definitions a
              # first-class fragment spread type may need to be created at they
              # type level and used in the query tree.

              # inline the fragment builder
              builder.child_builders.concat fragment_builder.child_builders
            end
          end
        end

        def validate_fragment_builder!(
          type_klass:,
          builder:
        )
          valid_types = type_klass.valid_fragment_type_names

          if builder.type_builder.blank?
            raise(InvalidFragment,
              "Fragment #{fragment_builder.fragment_name} is not defined"
            )
          end

          if valid_types.excludes? builder.fragment_defined_on
            msg = <<-ERROR.strip_heredoc.gsub("\n", "").strip
              Fragment is defined on #{builder.fragment_defined_on}
              but fragment spread is on an incompatible type
              (#{type_klass.type_name})
            ERROR
            raise InvalidFragment, msg
          end
        end

      end
    end
  end
end
