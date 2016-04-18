require "active_model/callbacks"

module RailsQL
  module DataType
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
      end

      class String < Base
      end

      class Integer < Base
      end

      class Float < Base
      end

      class Boolean < Base
      end

      class JSON < Base
      end

    end
  end
end