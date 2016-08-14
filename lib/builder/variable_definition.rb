# # Pending dev time

module RailsQL
  module Builder
    class VariableDefinition
      attr_accessor(
        :variable_name,
        :of_type,
        :default_value_node,
        :value_node
      )

    end
  end
end
