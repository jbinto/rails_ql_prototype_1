require_relative "./type.rb"

module RailsQL
  class Type
    # Introspection
    field(:__typename,
      resolve: ->(args, child_query) {
        self.type_name
      },
      introspection: true
    )
  end
end
