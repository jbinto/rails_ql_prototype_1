# Normalizes fragment builders and unions of fragment builders into
# types builders
module RailsQL
  module Builder
    class Normalizer

      # Recursively normalizes a type builder by inlining directives and
      # fragments and making fragments on unioned types explicit
      def self.normalize!(
        field_definition: nil,
        type_klass: nil,
        builder:
      )
        # normalize fragments on non-unions (inlining)
        inline_fragment_builders!(
          builder: builder
          type_klass: type_klass
        )
        # normalize directives (inlining)
        builder.child_builders.each do |child_builder|
          wrap_child_in_directives!(
            parent_builder: builder,
            child_builder: child_builder
          )
        end
        # normalize fragments on unions (nested builder instantiation)
        if type_klass.is_a? RailsQL::Union
        end
        # TODO: recurse into children
      end

      private

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

      def inline_fragment_builders!(
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
            builder.child_builders << *fragment_builder.child_builders
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
