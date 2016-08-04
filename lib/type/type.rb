require_relative "./class_methods.rb"

module RailsQL
  class Type
    extend RailsQL::Type::ClassMethods

    attr_reader :args, :ctx, :anonymous, :model, :aliased_as, :args_type
    attr_accessor :field_types, :query

    def initialize(
      ctx: {},
      root: false,
      anonymous: false,
      field_definition: nil,
      aliased_as:,
      args_type:,
      field_types: {}
    )
      @ctx = HashWithIndifferentAccess.new opts[:ctx]
      @root = root
      @anonymous = anonymous
      @field_definition = field_definition
      @args_type = args_type
      @field_types = field_types
      @name = name
      @aliased_as = aliased_as
    end

    def type_name
      self.class.field_definition.name
    end

    def field_or_arg_name
      self.field_definition.name
    end

    def initial_query
      if self.class.get_initial_query.present?
        instance_exec &self.class.get_initial_query
      end
    end

    def model=(value)
      @model = parse_value! value
    end

    def omit_from_json?
      false
    end

    def root?
      @root
    end

    def query_lambda
      @field_definition.try :query_lambda
    end

    def resolve_lambda
      @field_definition.try :resolve
    end

    def args
      @args_type.as_json
    end

    def query_tree_children
      field_types.values
    end

    def resolve_tree_children
      field_types.values
    end

    def can?(action, field_name)
      field_definitions[field_name].permissions[action].any? do |permission|
        instance_exec &permission
      end
    end

    def as_json
      kind = self.class.type_definition.kind
      if kind == :OBJECT
        json = field_types.reduce({}) do |json, (k, field)|
          if field.type.omit_from_json?
            json
          else
            child_json = field.type.as_json
            json.merge k.to_s => field.singular? ? child_json.first : child_json
          end
        end
      elsif kind == :ENUM || kind == :SCALAR
        json = model.as_json
      else
        raise "Kind #{kind} is not yet supported :("
      end
      return json
    end

    private

    def parse_value!(value)
      value
    end

  end
end
