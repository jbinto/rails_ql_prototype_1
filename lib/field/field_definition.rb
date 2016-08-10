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
          deprecated: false,
          deprecation_reason: "",
          child_ctx: {},
          default_value: nil, # InputObject field definitions only
          introspection: false
        }
      end

      attr_reader(
        *self.default_opts.except(:args, :resolve, :query).keys,   # XXX why not args?
        :name,
        :permissions,
        :resolve_lambda,
        :query_lambda
      )

      alias_method :deprecated?, :deprecated

      delegate :type_name, to: :type_klass

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

        opts[:resolve_lambda] = opts.delete :resolve
        opts[:query_lambda] = opts.delete :query

        @name = name
        @permissions = {query: [], mutate: [], input: []}.freeze

        opts[:description] = opts[:description].try :strip_heredoc

        opts.each do |key, value|
          instance_variable_set "@#{key}", value
        end
      end

      def type_klass
        RailsQL::Type::KlassFactory.find @type
      end

      # TODO: test that if the args lambda returns :whatever the args_type_klass
      # still returns the anonymous_input_object
      def args_type_klass
        if @args_type_klass.present?
          @args_type_klass
        else
          args_lambda = @args || ->(aio) {aio}
          anonymous_input_object = Class.new RailsQL::Type::AnonymousInputObject
          type_klass.instance_exec(
            anonymous_input_object,
            &args_lambda
          )
          @args_type_klass = anonymous_input_object
        end
      end

      def add_permission!(action, permission_lambda)
        valid_ops = @permissions.keys
        unless valid_ops.include? action
          raise <<-MSG.strip_heredoc.gsub("\n", " ").strip
            Cannot add #{action} to #{@name}.
            Operation must be one of :query, :mutate or :input"
          MSG
        end
        @permissions[action] << permission_lambda
      end

      def can?(action, on:)
        @permissions[action].any? do |permission|
          on.instance_exec &permission
        end
      end

    end
  end
end
