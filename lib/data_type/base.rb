require "active_model/callbacks"

module RailsQL
  module DataType
    class Base
      extend ActiveModel::Callbacks
      define_model_callbacks :resolve

      include Can

      PRIMITIVE_DATA_TYPES = %w(RailsQL::DataType::String)
      attr_reader :args, :ctx, :query
      attr_accessor :model, :fields

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
        @ctx = HashWithIndifferentAccess.new opts[:ctx]
        @root = opts[:root]
        if self.class.get_initial_query.present?
          @query = instance_exec &self.class.get_initial_query
        end
      end

      def root?
        @root
      end

      def build_query!
        # Bottom to top recursion
        fields.each do |k, field|
          field.prototype_data_type.build_query!
          @query = field.appended_parent_query
        end
        return query
      end

      def resolve_child_data_types!
        run_callbacks :resolve do
          # Top to bottom recursion
          fields.each do |k, field|
            field.parent_data_type = self
            field.resolve_models_and_dup_data_type!
            field.data_types.each &:resolve_child_data_types!
          end
        end
      end

      def as_json
        fields.reduce({}) do |json, (k, field)|
          child_json = field.data_types.as_json
          json.merge(
            k.to_s => field.singular? ? child_json.first : child_json
          )
        end
      end

      class << self
        def name(name=nil)
          @name ||= name ? name.strip : nil
        end

        def description(description=nil)
          @description ||= description ? description.strip : nil
        end

        def field_definitions
          @field_definitions ||= HashWithIndifferentAccess.new
        end

        def data_type?
          true
        end

        def initial_query(initial_query)
          @initial_query = initial_query
        end

        def get_initial_query
          @initial_query
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
        # * <tt>:data_type</tt> - Specifies the data_type
        # * <tt>:description</tt> - A description of the field
        # * <tt>:accessible_args</tt> - Arguments that can be passed to the resolve method
        # * <tt>:nullable</tt> -
        def field(name, opts={})
          instance_methods = (
            RailsQL::DataType::Base.instance_methods - Object.instance_methods
          )

          name = name.to_s
          if name.include?("__") && name != "__type" && name != "__schema"
            raise(
              RailsQL::InvalidField,
              "#{name} is an invalid field; names must not be " +
              "prefixed with double underscores"
            )
          end

          if (instance_methods).include?(name.to_sym) && opts[:resolve].nil?
            raise(
              RailsQL::InvalidField,
              "Reserved word: Can not use #{name} as a field name without a " +
              ":resolve option"
            )
          end

          field_definitions[name] = FieldDefinition.new name.to_sym, opts
        end

        def has_one(name, opts={})
          field name, opts.merge(singular: true)
        end

        def has_many(name, opts={})
          field name, opts.merge(singular: false)
        end

      end
    end

  end
end
