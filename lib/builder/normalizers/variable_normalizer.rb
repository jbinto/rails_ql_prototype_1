module RailsQL
  module Builder
    module Normalizers
      class VariableNormalizer

        def initialize(variable_definition_builders:)
          @variable_definition_builders = variable_definition_builders
        end

        # Injects the values of variables into the child builders of this
        # type builder
        # Should be called recursively on each builder/type_klass/
        # field_definition.
        def normalize!(
          field_definition: nil,
          type_klass:,
          builder:
        )
          # Inject variable builders into the list of args (do nothing for fields)
          child_builders = builder.child_builders
          builder.variables.each do |argument_name, variable_name|
            if @variable_builders[argument_name].blank?
              raise MissingVariableDefinition, <<-ERROR
                Variable not defined in operation: #{variable_name}
              ERROR
            end
            variable_builder = @variable_builders[argument_name].dup
            variable_builder.name = argument_name
            variable_builder.aliased_as = argument_name
            child_builders << variable_builder
          end
        end

      end
    end
  end
end
