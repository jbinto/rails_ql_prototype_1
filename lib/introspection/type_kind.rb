require_relative "../type/kind.rb"

module RailsQL
  module Introspection
    class TypeKind  < RailsQL::Type
      type_name "__TypeKind"

      kind :enum
      enum_values *RailsQL::Type::Kind.enum_values

    end
  end
end
