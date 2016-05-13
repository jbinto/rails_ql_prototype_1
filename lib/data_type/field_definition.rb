module RailsQL
  module DataType
    class FieldDefinition
      attr_writer(
        :deprecated
      )
      attr_accessor(
        :deprecation_reason
      )
      attr_reader(
        :data_type,
        :required_args,
        :optional_args,
        :description,
        :nullable,
        :child_ctx,
        :name,
      )

      ARG_TYPE_TO_RUBY_CLASSES = {
        IntValue: [Fixnum],
        FloatValue: [Float],
        StringValue: [String],
        BooleanValue: [TrueClass, FalseClass],
        EnumValue: [String, Fixnum],
        ListValue: [Array],
        ObjectValue: [Hash]
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
          deprecated: false,
          singular: true,
          child_ctx: {},
          resolve: nil,
          query: nil
        }
        opts = defaults.merge(opts.slice *defaults.keys)
        if opts[:description]
          opts[:description] = opts[:description].gsub(/\n\s+/, "\n").strip
        end
        opts.each do |key, value|
          instance_variable_set "@#{key}", value
        end

        validate_arg_types!
      end

      def data_type_klass
        KlassFactory.find @data_type
      end

      def args
        args = optional_args.merge required_args
        args
          .map{|k, v| [k.to_sym, v.to_sym]}
          .to_h
      end

      def deprecated?
        @deprecated
      end

      def validate_arg_types!
        invalid_arg_types = args.values - ARG_TYPES
        return if invalid_arg_types.empty?
        raise(
          InvalidArgType,
          "#{invalid_arg_types} on #{@name} are not valid arg types"
        )
      end

      def arg_value_matches_type?(k, v)
        ARG_TYPE_TO_RUBY_CLASSES[args[k.to_sym]].include? v.class
      end

      def arg_whitelist
        args.keys
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

      def append_to_query(parent_data_type:, args: {}, child_query: nil)
        if @query.present?
          parent_data_type.instance_exec(
            args,
            child_query,
            &@query
          )
        else
          parent_data_type.query
        end
      end

      def resolve(parent_data_type:, args: {}, child_query: nil)
        if @resolve.present?
          parent_data_type.instance_exec(
            args,
            child_query,
            &@resolve
          )
        elsif parent_data_type.respond_to? @name
          parent_data_type.send @name
        else
          parent_data_type.model.try @name
        end
      end
    end
  end
end
