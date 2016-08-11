require_relative "./type_builder.rb"

module RailsQL
  module Builder
    class VariableReferenceBuilder < TypeBuilder
      attr_accessor(
        :name,
        :of_type,
        :variable_name,
        :variable_definition_builder
      )

    end
  end
end
