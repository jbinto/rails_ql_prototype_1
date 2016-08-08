# Normalizes fragment builders and unions of fragment builders into
# types builders
module RailsQL
  module Builder
    class Normalizer

      # Recursively build and return an instance of `type_klass` and it's
      # children based on the builder, field definition and ctx.
      def self.normalize!(field_definition: nil, builder:, ctx:)
        # normalize directives (inlining)
        builder.child_builders.each do |child_builder|
          wrap_child_in_directives!(
            parent_builder: builder,
            child_builder: child_builder
          )
        end
        # normalize fragments on non-unions (inlining)
        if builder.is_a? FragmentBuilder
          validate_fragment_builder!(
            type_klass: type_klass,
            builder: builder
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
          # this idempotent)
          child_builder.first_directive_builder = nil
          # replace the field with it's directive (now wrapping the child)
          index = builder.child_builders.index_of child_builder
          parent_builder.child_builders[index] = directive_builder
        end
      end

      def validate_fragment_builder!(
        type_klass:,
        builder:
      )
        if builder.type_builder.blank?
          raise(InvalidFragment,
            "Fragment #{fragment_builder.fragment_name} is not defined"
          )
        end
        if builder.fragment_defined_on != type_klass.type_definition.type_name
          msg = <<-ERROR.strip_heredoc.gsub("\n", "").strip
            Fragment is defined on #{builder.fragment_defined_on}
            but fragment spread is on an incompatible type
            (#{type_klass.type_definition.type_name})
          ERROR
          raise InvalidFragment, msg
        end
      end

    end
  end
end
