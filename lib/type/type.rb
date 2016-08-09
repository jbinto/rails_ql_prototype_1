require_relative "./class_methods.rb"

module RailsQL
  class Type
    extend RailsQL::Type::ClassMethods

    attr_reader :args, :ctx, :anonymous, :model, :aliased_as, :args_type
    attr_accessor :field_types, :query

    delegate :type_name, to: :class

    def initialize(
      aliased_as:,
      args_type:,
      ctx: {},
      root: false,
      anonymous: false,
      field_definition: nil,
      field_types: {}
    )
      raise "args_type cannot be nil" if args_type.nil?
      raise "aliased_as cannot be nil" if aliased_as.nil?
      @ctx = HashWithIndifferentAccess.new ctx
      @root = root
      @anonymous = anonymous
      @field_definition = field_definition
      @args_type = args_type
      @field_types = field_types
      @aliased_as = aliased_as
    end

    def field_or_arg_name
      # XXX: ??? was self.field_definition?
      # TypeBuilder will give this to us? even for args?
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
      # FAIL:
      # the RailsQL::Field::FieldDefinition class does not implement the instance method: query_lambda
      @field_definition.try :query_lambda
    end

    def resolve_lambda
      @field_definition.try :resolve
    end

    def args
      # that this works when @args_type is nil is just a massive rails-driven
      # coincidence
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
      binding.pry
      if kind == :OBJECT
        json = field_types.reduce({}) do |json, (k, child_type)|
          if child_type.omit_from_json?
            json
          else
            json.merge(
              k.to_s => child_type.as_json
            )
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
