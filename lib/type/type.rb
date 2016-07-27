require "active_model/callbacks"
require_relative "./class_methods.rb"
require_relative "../field/field_collection.rb"

module RailsQL
  class Type
    extend ActiveModel::Callbacks
    extend RailsQL::Type::ClassMethods

    # Introspection
    field(:__typename,
      resolve: ->(args, child_query) {
        self.class.field_definition.name
      },
      introspection: true
    )

    define_model_callbacks :resolve
    before_resolve :authorize_query!, if: :root?

    attr_reader :args, :ctx, :query, :anonymous, :model
    attr_accessor :fields

    def initialize(opts={})
      opts = {
        child_types: {},
        args: {},
        ctx: {},
        root: false,
        anonymous: false
      }.merge opts

      @args = HashWithIndifferentAccess.new(opts[:args]).freeze
      @ctx = HashWithIndifferentAccess.new opts[:ctx]
      @root = opts[:root]
      @anonymous = opts[:anonymous]
      if self.class.get_initial_query.present?
        @query = instance_exec &self.class.get_initial_query
      end
    end

    def authorize_for!(action)
      unauthorized = unauthorized_fields_for action
      if unauthorized.present?
        raise UnauthorizedQuery, "unauthorized fields: #{unauthorized.to_json}"
      end
    end

    def unauthorized_fields_for(action)
      self.fields.unauthorized_fields_for action, self
    end

    def root?
      @root
    end

    def build_query!
      # Bottom to top recursion
      fields.each do |k, field|
        field.prototype_type.build_query!
        @query = field.appended_parent_query
      end
      return query
    end

    def resolve_child_types!
      # Top to bottom recursion
      run_callbacks :resolve do
        fields.values.each &:resolve_child_types!
      end
    end

    def as_json
      kind = self.class.type_definition.kind
      if kind == :OBJECT
        json = fields.reduce({}) do |json, (k, field)|
          field.inject_json parent_json: json, key: k.to_s
        end
      elsif kind == :ENUM || kind == :SCALAR
        json = model.as_json
      else
        raise "Kind #{kind} is not yet supported :("
      end
      return json
    end

    def model=(value)
      @model = parse_value! value
    end

    def parse_value!(value)
      value
    end
  end
end
