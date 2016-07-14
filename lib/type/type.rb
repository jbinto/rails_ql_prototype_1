require "active_model/callbacks"
require_relative "./field_definition"

module RailsQL
  class Type
    extend ActiveModel::Callbacks
    define_model_callbacks :resolve
    after_resolve :authorize_query!, if: :root?

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

    def authorize_for!(action)
      unauthorized = unauthorized_fields_for action
      if unauthorized.present?
        raise UnauthorizedQuery, "unauthorized fields: #{unauthorized.to_json}"
      end
    end

    def unauthorized_fields_for(action)
      self.class.field_definitions.unauthorized_fields_for action, self
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
      kind = self.class.type_definition.kind
      if kind == :OBJECT
        json = fields.reduce({}) do |json, (k, field)|
          child_json = field.data_types.as_json
          json.merge(
            k.to_s => field.singular? ? child_json.first : child_json
          )
        end
      elsif kind == :ENUM
        json = model.as_json
      else
        raise "Kind #{kind} is not yet supported :("
      end
      return json
    end

    class << self
      include RailsQL::Type::ClassMethods
    end
  end
end
