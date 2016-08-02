require_relative "../type/klass_factory.rb"
require_relative "../type/type.rb"

module RailsQL
  module Field
    class FieldDefinition

      def self.default_opts
        {
          type: nil,
          description: nil,
          args: nil,
          resolve: nil,
          query: nil,
          nullable: true,
          deprecated: false,
          deprecation_reason: "",
          singular: true,
          union: false,
          child_ctx: {},
          default_value: nil, # InputObject field definitions only
          introspection: false
        }
      end

      attr_reader(
        *self.default_opts.except(:args).keys,
        :name,
        :permissions
      )

      alias_method :deprecated?, :deprecated
      alias_method :nullable?, :nullable
      alias_method :singular?, :singular

      def initialize(name, opts)
        defaults = self.class.default_opts
        opts = defaults.merge opts.slice *defaults.keys

        unless opts[:child_ctx].respond_to?(:keys)
          raise "ctx must be a Hash"
        end

        opts.slice(:args, :resolve, :query).each do |k, v|
          next if v.blank? || v.respond_to?(:call)
          raise ":#{k} must be either nil or a Lambda"
        end

        @name = name
        @permissions = {query: [], mutate: [], input: []}.freeze

        opts[:type] ||= "#{name.to_s.singularize.classify}Type"

        opts[:description] = opts[:description].try :strip_heredoc

        opts.each do |key, value|
          instance_variable_set "@#{key}", value
        end
      end

      def type_klass
        RailsQL::Type::KlassFactory.find @type
      end

      def args
        if @evaled_args.present?
          @evaled_args
        else
          anonymous_input_object = Class.new RailsQL::Type::AnonymousInputObject
          @evaled_args = type_klass.instance_exec @args, anonymous_input_object
        end
      end

      def add_permission!(operation, permission_lambda)
        valid_ops = @permissions.keys
        unless valid_ops.include? operation
          raise <<-MSG.strip_heredoc.gsub("\n", " ").strip
            Cannot add #{operation} to #{@name}.
            Operation must be one of :query, :mutate or :input"
          MSG
        end
        @permissions[operation] << permission_lambda
      end

      def append_to_query(parent_type:, args: {}, child_query: nil)
        if @query.present?
          parent_type.instance_exec(
            args,
            child_query,
            &@query
          )
        else
          default_query(
            parent_type: parent_type,
            args: args,
            child_query: child_query
          )
        end
      end

      def resolve(parent_type:, args: {}, child_query: nil)
        if @resolve.present?
          parent_type.instance_exec(
            args,
            child_query,
            &@resolve
          )
        else
          default_resolve(
            parent_type: parent_type,
            args: args,
            child_query: child_query
          )
        end
      end

      private

      def default_query(parent_type:, args: {}, child_query: nil)
        parent_type.query
      end

      def default_resolve(parent_type:, args: {}, child_query: nil)
        if parent_type.respond_to? @name
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
