module RailsQL
  module Builder
    module Reducers
      class VariableNormalizer

        def initialize(variable_definitions:)
          @variable_definitions = variable_definitions
        end

        # Injects the values of variables into the child builders of this
        # type builder
        # Should be called recursively on each node
        def visit_node(
          node:,
          parent_nodes:
        )
          node = node.shallow_clone_node
          # Inject variable builders into the list of args (no-op for fields)
          node.variables.each do |argument_name, variable_name|
            variable_def_node = @variable_definitions[argument_name]

            if variable_def_node.blank?
              raise MissingVariableDefinition, <<-ERROR
                Variable not defined in operation: #{variable_name}
              ERROR
            end

            # Create a node for the field with the variable's model and/or
            # child nodes
            node.child_nodes << Node.new(
              name: argument_name,
              aliased_as: argument_name,
              model: variable_def_node.model,
              child_nodes: variable_def_node.child_nodes
            )
          end

          node
        end

      end
    end
  end
end
