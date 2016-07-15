module RailsQL
  class Type
    class Builder
      attr_reader :type_klass

      def initialize(opts)
        if opts[:type_klass].blank?
          raise "requires a :type_klass option"
        end
        @type_klass = KlassFactory.find opts[:type_klass]
        @child_builders = {}
        @union_child_builders = {}
        @ctx = opts[:ctx]
        @root = opts[:root]
        @is_arg_value = opts[:is_arg_value]
        @args = {}
      end

      def type
        children = @child_builders.reduce({}) do |types, (type, builder)|
          types[type] = builder.type
          types
        end
        @type ||= type_klass.new(
          args: @args,
          child_types: children,
          ctx: @ctx,
          root: @root
        )
      end

      # idempotent
      def add_child_builder(name)
        if field_definitions[name] == nil
          raise "Invalid field #{name} on #{@type_klass}"
        end
        return @child_builders[name] if @child_builders[name].present?

        field_definition = field_definitions[name]
        type_klass = field_definition.type

        child_builder = Builder.new(
          type_klass: type_klass,
          ctx: @ctx.merge(field_definition.child_ctx),
          root: false
        )

        @child_builders[name] = child_builder
        return child_builder
      end

      # idempotent
      def add_arg(name, value)
        @args[name.to_s] = value
      end

      def child_builders
        @child_builders.clone
      end

      def args
        @args.clone
      end

      def unresolved_fragments
        @unresolved_fragments ||= []
      end

      private

      def field_definitions
        type_klass.field_definitions
      end

    end
  end
end
