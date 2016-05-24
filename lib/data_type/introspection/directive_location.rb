require_relative "../kind.rb"

module RailsQL
  module DataType
    module Introspection
      class DirectiveLocation < Base
        kind :ENUM
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
end
