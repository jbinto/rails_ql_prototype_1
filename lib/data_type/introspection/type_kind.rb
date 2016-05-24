require_relative "../kind.rb"

module RailsQL
  module DataType
    module Introspection
      class TypeKind < Base
        kind :ENUM
        enum_values *RailsQL::DataType::Kind.enum_values

      end
    end
  end
end
