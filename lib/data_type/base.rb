require "active_model/callbacks"

module RailsQL
  module DataType
    class Base
      extend ActiveModel::Callbacks
      define_model_callbacks :resolve

      include Can

      PRIMITIVE_DATA_TYPES = %w(RailsQL::DataType::String)
      attr_reader :args, :ctx, :fields, :query
      attr_accessor :model

      def initialize(opts={})
        opts = {
          child_data_types: {},
          args: {},
          ctx: {},
          root: false
        }.merge opts
        @fields = HashWithIndifferentAccess.new
        opts[:child_data_types].each do |name, data_type|
          @fields[name] = Field.new(
            name: name,
            field_definition: self.class.field_definitions[name],
            parent_data_type: self,
            data_type: data_type
          )
        end
        @fields.freeze
        @args = HashWithIndifferentAccess.new(opts[:args]).freeze
        @ctx = HashWithIndifferentAccess.new(opts[:ctx]).freeze
        @root = opts[:root]
      end

      def root?
        @root
      end

      def build_query!
        @query = self.class.call_initial_query
        @fields.each do |name, field|
          @query = field.add_to_parent_query!
        end
      end

      def resolve_child_data_types!
        run_callbacks :resolve do
          @fields.each {|name, field| field.resolve!}
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

        def data_type?
          true
        end

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

          @field_definitions ||= HashWithIndifferentAccess.new
          @field_definitions[name] = FieldDefinition.new name.to_sym, opts
        end

        alias_method :has_many, :field
        alias_method :has_one, :field

      end
    end

  end
end


