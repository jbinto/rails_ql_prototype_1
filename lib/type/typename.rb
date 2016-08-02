require_relative "./type.rb"

module RailsQL
  class Type
    # Introspection
    field(:__typename,
      resolve: ->(args, child_query) {
        self.class.field_definition.name
      },
      introspection: true
    )
  end
end
