require_relative "../type/kind.rb"

module RailsQL
  module Introspection
    class DirectiveLocation  < RailsQL::Type
      type_name "__DirectiveLocation"

      kind :enum
      enum_values(
        :QUERY,
        :MUTATION,
        :FIELD,
        :FRAGMENT_DEFINITION,
        :FRAGMENT_SPREAD,
        :INLINE_FRAGMENT
      )

    end
  end
end
