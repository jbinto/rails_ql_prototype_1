module RailsQL
  module DataType
    class Builder
      attr_reader :data_type_klass

      def initialize(opts)
        if opts[:data_type_klass].blank?
          raise "requires a :data_type_klass option"
        end
        @data_type_klass = KlassFactory.find opts[:data_type_klass]
        @child_builders = {}
        @ctx = opts[:ctx]
        @root = opts[:root]
        @args = {}
      end

      def data_type
        children = @child_builders.reduce({}) do |types, (type, builder)|
          types[type] = builder.data_type
          types
        end
        @data_type ||= data_type_klass.new(
          args: @args,
          child_data_types: children,
          ctx: @ctx,
          root: @root
        )
      end

      # idempotent
      def add_child_builder(name)
        if field_definitions[name] == nil
          raise "Invalid field #{name} on #{@data_type_klass}"
        end
        return @child_builders[name] if @child_builders[name].present?

        field_definition = field_definitions[name]
        data_type_klass = field_definition.data_type

        begin
          child_builder = Builder.new(
            data_type_klass: data_type_klass,
            ctx: @ctx.merge(field_definition.child_ctx),
            root: false
          )
        rescue Exception => e
          message = "In #{@data_type_klass}: #{e.message}"
          raise e, message, e.backtrace
        end

        @child_builders[name] = child_builder
        return child_builder
      end

      def add_union_child_builder(name)
        # does not return a builder
      end

      def add_union_child_builder_field(name)
        # must return a builder
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

      # def add_unresolved_fragment
      # end

      private

      def field_definitions
        data_type_klass.field_definitions
      end

    end
  end
end
