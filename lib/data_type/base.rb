require "active_model/callbacks"

module RailsQL
  module DataType
    class Base
      extend ActiveModel::Callbacks
      define_model_callbacks :resolve

      PRIMITIVE_DATA_TYPES = %w(RailsQL::DataType::String)
      attr_reader :args
      attr_accessor :model

      def initialize(opts={})
        opts = {
          fields: {},
          args: {}
        }.merge opts
        @fields = HashWithIndifferentAccess.new(opts[:fields]).freeze
        @args = HashWithIndifferentAccess.new(opts[:args]).freeze
        @context = HashWithIndifferentAccess.new(opts[:context]).freeze
        @root = opts[:root]
      end

      def root?
        @root
      end

      def query
        initial_query = self.class.call_initial_query
        @fields.reduce(initial_query) do |query, (name, child_data_type)|
          definition = self.class.field_definitions[name.to_sym]
          definition.add_to_parent_query(
            args: child_data_type.args,
            parent_query: query,
            child_query: child_data_type.query
          )
        end
      end

      def resolve_child_data_types
        run_callbacks :resolve do
          @fields.each do |name, data_type|
            definition = self.class.field_definitions[name.to_sym]
            data_type.model = definition.resolve(
              parent_data_type: self,
              parent_model: model
            )
            data_type.resolve_child_data_types
          end
        end
      end

      def as_json
        @fields.reduce({}) do |json, (name, data_type)|
          json.merge(
            name.to_sym => data_type.as_json
          )
        end
      end

      class << self
        attr_reader :field_definitions

        def initial_query(initial_query)
          @initial_query = initial_query
        end

        def call_initial_query
          return @initial_query.call
        end

        # Adds a FieldDefinition to the data type
        #
        #   class UserType < RailsQL::DataType::Base
        #
        #     field(:email,
        #       data_type: RailsQL::DataType::String
        #     )
        #   end
        #
        # Options:
        # * <tt>:data_type</tt> - Specifies the primtive data_type
        # * <tt>:description</tt> - A description of the field
        # * <tt>:args</tt> - Arguments to be passed to the resolve method
        # * <tt>:nullable</tt> -
        def field(name, opts={})
          instance_methods = (
            RailsQL::DataType::Base.instance_methods - Object.instance_methods
          )

          if (instance_methods).include? name
            raise "Reserved word: Can not use #{name} as a field name"
          end

          @field_definitions ||= {}
          @field_definitions[name] = FieldDefinition.new name.to_sym, opts
        end

        alias_method :has_many, :field
        alias_method :has_one, :field

      end
    end

  end
end


