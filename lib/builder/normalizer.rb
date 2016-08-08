# Normalizes fragment builders and unions of fragment builders into
# types builders
module RailsQL
  module Builder
    class Normalizer

      # Recursively build and return an instance of `type_klass` and it's
      # children based on the builder, field definition and ctx.
      def self.normalize!(field_definition: nil, type_klass:, builder:, ctx:)
        if builder.is_a? FragmentBuilder
          validate_fragment_builder!(
            type_klass: type_klass,
            builder: builder
          )
        end
        if type_klass.is_a? RailsQL::Union
        end
        # TODO: recurse into children
      end

      private

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
