require_relative "./type.rb"

module RailsQL
  class Type
    # Introspection
    field(:__typename,
      type: :String,
      resolve: ->(args, child_query) {
        self.type_name
      },
      introspection: true
    )
  end
end
