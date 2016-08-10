require_relative "./class_methods.rb"

module RailsQL
  class Type
    extend RailsQL::Type::ClassMethods

    attr_reader :args, :ctx, :anonymous, :model, :aliased_as, :args_type
    attr_accessor :field_types, :query, :field_definition

    delegate :type_name, to: :class

    def initialize(
      args_type: nil,
      aliased_as: nil,
      ctx: {},
      root: false,
      anonymous: false,
      field_definition: nil,
      field_types: {}
    )
      @ctx = ctx
      @root = root
      @anonymous = anonymous
      @field_definition = field_definition
      @args_type = args_type
      @field_types = field_types
      @aliased_as = aliased_as
    end

    def field_or_arg_name
      @field_definition.name
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
      @field_definition.try :resolve_lambda
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
      self.class.can? action, field_name, on: self
    end

    def as_json
      kind = self.class.type_definition.kind
      if kind == :object
        json = field_types.reduce({}) do |json, (k, child_type)|
          if child_type.omit_from_json?
            json
          else
            json.merge(
              k.to_s => child_type.as_json
            )
          end
        end
      elsif kind == :enum || kind == :scalar
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
