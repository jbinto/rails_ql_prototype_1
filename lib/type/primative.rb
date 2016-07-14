require "active_model/callbacks"

module RailsQL
  class Type
    module Primative

      def self.data_type_names
        Primative.constants.select do |c|
          Primative.const_get(c).is_a? Class
        end
      end

      class Base
        attr_reader :args, :ctx, :query
        attr_accessor :model, :fields

        alias_method :as_json, :model

        extend ActiveModel::Callbacks
        define_model_callbacks :resolve

        include Can

        def initialize(opts)
          @fields = {}
          @args = {}
        end

        def root?
          false
        end

        def build_query!
        end

        def resolve_child_data_types!
        end

        def self.data_type?
          true
        end

        def self.field_definitions
          {}
        end

        def self.type_definition(description=nil)
          @type_definition ||= OpenStruct.new(
            name: to_s.gsub("RailsQL::Type::Primative::", ""),
            kind: :SCALAR,
            enum_values: nil,
            description: description
          )
        end
      end

      class String  < RailsQL::Type
        type_definition(
          "The `String` scalar type represents textual data, represented as " +
          "UTF-8 character sequences. The String type is most often used by " +
          "GraphQL to represent free-form human-readable text."
        )
      end

      class Int  < RailsQL::Type
        type_definition(
          "The `Int` scalar type represents non-fractional signed whole numeric " +
          "values. Int can represent values between -(2^53 - 1) and 2^53 - 1 " +
          "since represented in JSON as double-precision floating point numbers " +
          "specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point)."
        )
      end

      class Float  < RailsQL::Type
        type_definition(
          "The `Float` scalar type represents signed double-precision " +
          "fractional values as specified by " +
          "[IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point). "
        )
      end

      class Boolean  < RailsQL::Type
        type_definition(
          "The `Boolean` scalar type represents `true` or `false`."
        )
      end

      class JSON  < RailsQL::Type
        type_definition(
          "The `JSON` scalar type represents object data which does not " +
          "neccessarily need a data type of its own. It can contain any other " +
          "scalar."
        )
      end

    end
  end
end
