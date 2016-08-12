# Normalizes fragment builders and unions of fragment builders into
# types builders
module RailsQL
  module Builder
    module Reducers
      class FragmentTypeChecker

        # Validates that each fragment spread on the node is defined on a type
        # that is valid for this type.
        # Should be called recursively on each builder/type_klass/
        # field_definition.
        #
        # Examples
        #
        # Where thing is of Object Type `Thing` this is GOOD
        # ```
        #   query { thing: {...thingFrag} }
        #   fragment on Thing {name}
        # ```
        #
        # Where thing_union is of Union Type `ThingUnion` which unions `Thing`
        # this is GOOD
        # ```
        #   query { thing_union: {...thingFrag} }
        #   fragment on Thing {name}
        # ```
        #
        # Where not_a_thing is of Object Type `NotAThing` this is BAD
        # ```
        #   query { not_a_thing: {...thingFrag} }
        #   fragment on Thing {name}
        # ```
        #
        def visit_node(
          field_definition: nil,
          type_klass:,
          node:,
          parent_nodes:
        )
          original_node.annotation.fragment_spread_nodes.each do |fragment_node|
            validate_fragment_builder!(
              type_klass: type_klass,
              fragment_annotation: fragment_node
            )
          end

          original_node
        end

        private

        def validate_fragment_builder!(
          type_klass:,
          fragment_annotation:
        )
          valid_types = type_klass.valid_fragment_type_names

          unless fragment_annotation.defined_fragment?
            raise(InvalidFragment,
              "Fragment #{fragment_annotation.fragment_name} is not defined"
            )
          end

          if valid_types.excludes? fragment_annotation.fragment_defined_on
            msg = <<-ERROR.strip_heredoc.gsub("\n", "").strip
              Fragment is defined on #{fragment_annotation.fragment_defined_on}
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
