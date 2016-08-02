module RailsQL
  module Field
    class FieldDefinition
      attr_writer(
        :deprecated
      )
      attr_accessor(
        :deprecation_reason
      )
      attr_reader(
        :type,
        :args,
        :description,
        :nullable,
        :child_ctx,
        :union,
        :name,
        :singular,
        :introspection
      )

      def initialize(name, opts)
        @name = name
        @permissions = {query: [], mutate: [], input: []}

        opts.slice(:child_ctx).each do |k, v|
          next if v.blank? || v.respond_to?(:keys)
          raise ":#{k} must be a Hash"
        end
        opts.slice(:args, :resolve, :query).each do |k, v|
          next if v.blank? || v.respond_to?(:call)
          raise ":#{k} must be either nil or a Lambda"
        end

        defaults = {
          type: "#{name.to_s.singularize.classify}Type",
          description: nil,
          args: ->(args){},
          nullable: true,
          deprecated: false,
          singular: true,
          union: false,
          child_ctx: {},
          resolve: nil,
          query: nil,
          default_value: nil, # InputObject field definitions only
          introspection: false
        }
        opts = defaults.merge(opts.slice *defaults.keys)
        if opts[:description]
          opts[:description] = opts[:description].gsub(/\n\s+/, "\n").strip
        end
        opts.each do |key, value|
          instance_variable_set "@#{key}", value
        end
      end

      def type_klass
        KlassFactory.find @type
      end

      def args
        @evaled_args ||=(
          anonymous_input_object = Class.new(RailsQL::Type) do
            kind :input_object
            anonymous true
          end
          type.instance_exec anonymous_input_object, &@args
        )
      end

      def deprecated?
        @deprecated
      end

      def add_permission(operation, permission_lambda)
        @permissions[operation] << permission_lambda
      end

      def nullable?
        @nullable
      end

      def singular?
        @singular
      end

      def permissions
        if @permissions.present?
          @permissions.clone
        else
          [->{false}]
        end
      end

      def append_to_query(parent_type:, args: {}, child_query: nil)
        if @query.present?
          parent_type.instance_exec(
            args,
            child_query,
            &@query
          )
        else
          parent_type.query
        end
      end

      def resolve(parent_type:, args: {}, child_query: nil)
        if @resolve.present?
          parent_type.instance_exec(
            args,
            child_query,
            &@resolve
          )
        elsif parent_type.respond_to? @name
          parent_type.send @name
        elsif parent_type.model.respond_to? @name
          parent_type.model.send @name
        else
          raise(
            RailsQL::NullResolve,
            "#{parent_type.class}##{@name} does not have an explicit " +
            "resolve, nor does the model respond to :#{@name}."
          )
        end
      end
    end
  end
end
