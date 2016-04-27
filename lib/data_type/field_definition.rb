module RailsQL
  module DataType
    class FieldDefinition
      attr_reader :data_type, :required_args, :optional_args, :description,
        :nullable, :query, :resolve, :child_ctx

      ARG_TYPE_TO_RUBY_CLASSES = {
        "IntValue" => [Fixnum],
        "FloatValue" => [Float],
        "StringValue" => [String],
        "BooleanValue" => [TrueClass, FalseClass],
        "EnumValue" => [String, Fixnum],
        "ListValue" => [Array],
        "ObjectValue" => [Hash]
      }

      ARG_TYPES = ARG_TYPE_TO_RUBY_CLASSES.keys

      def initialize(name, opts)
        @name = name
        @read_permissions = []

        opts.slice(:required_args, :optional_args, :child_ctx).each do |k, v|
          next if v.blank? || v.respond_to?(:keys)
          raise ":#{k} must be a Hash"
        end
        opts.slice(:resolve, :query).each do |k, v|
          next if v.blank? || v.respond_to?(:call)
          raise ":#{k} must be either nil or a Lambda"
        end

        defaults = {
          data_type: "#{name.to_s.singularize.classify}DataType",
          description: nil,
          required_args: {},
          optional_args: {},
          nullable: true,
          singular: true,
          child_ctx: {},
          resolve: nil,
          query: nil
        }
        opts = defaults.merge(opts.slice *defaults.keys)
        opts.each do |key, value|
          instance_variable_set "@#{key}", value
        end

        validate_arg_types!
      end

      def validate_arg_types!
        arg_types = optional_args.merge(required_args).values

        unless (invalid_arg_types = arg_types - ARG_TYPES).empty?
          raise(
            InvalidArgType,
            "#{invalid_arg_types} on #{@name} are not valid arg types"
          )
        end
      end

      def arg_value_matches_type?(k, v)
        arg_type = optional_args.merge(required_args).symbolize_keys[k.to_sym]

        ARG_TYPE_TO_RUBY_CLASSES[arg_type].include? v.class
      end

      def arg_whitelist
        optional_args.merge(required_args).keys.map &:to_sym
      end

      def add_read_permission(lambda)
        @read_permissions << lambda
      end

      def nullable?
        @nullable
      end

      def singular?
        @singular
      end

      def read_permissions
        if @read_permissions.present?
          @read_permissions.clone
        else
          [->{false}]
        end
      end

    end
  end
end
