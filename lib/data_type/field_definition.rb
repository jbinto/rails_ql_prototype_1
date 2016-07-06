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
        :args,
        :description,
        :nullable,
        :child_ctx,
        :union,
        :name,
        :singular
      )

      ARG_TYPE_TO_RUBY_CLASSES = {
        Int: [Fixnum],
        Float: [Float],
        String: [String],
        Boolean: [TrueClass, FalseClass],
        EnumValue: [String, Fixnum],
        ListValue: [Array],
        ObjectValue: [Hash]
      }

      ARG_TYPES = ARG_TYPE_TO_RUBY_CLASSES.keys

      def initialize(name, opts)
        @name = name
        @read_permissions = []

        opts.slice(:child_ctx).each do |k, v|
          next if v.blank? || v.respond_to?(:keys)
          raise ":#{k} must be a Hash"
        end
        opts.slice(:args, :resolve, :query).each do |k, v|
          next if v.blank? || v.respond_to?(:call)
          raise ":#{k} must be either nil or a Lambda"
        end

        defaults = {
          data_type: "#{name.to_s.singularize.classify}DataType",
          description: nil,
          args: ->(args){},
          nullable: true,
          deprecated: false,
          singular: true,
          union: false,
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
      end

      def data_type_klass
        KlassFactory.find @data_type
      end

      def args
        @evaled_args ||=(
          anonymous_input_object = Class.new InputObject
          anonymous_input_object.anonymous = true
          parent_data_type.instance_exec anonymous_input_object, &@args
        )
      end

      def deprecated?
        @deprecated
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
        elsif parent_data_type.model.respond_to? @name
          parent_data_type.model.send @name
        else
          raise(
            RailsQL::NullResolve,
            "#{parent_data_type.class}##{@name} does not have an explicit " +
            "resolve, nor does the model respond to :#{@name}."
          )
        end
      end
    end
  end
end
