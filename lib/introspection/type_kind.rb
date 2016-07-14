require_relative "../kind.rb"

module RailsQL
  module Introspection
    class TypeKind  < RailsQL::Type
      type_name "__TypeKind"

      kind :ENUM
      enum_values *RailsQL::Type::Kind.enum_values

    end
  end
end
