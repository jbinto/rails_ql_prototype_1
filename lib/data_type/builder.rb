module RailsQL
  module DataType
    class Builder
      attr_reader :data_type_klass

      def initialize(opts)
        if opts[:data_type_klass].blank?
          raise "requires a :data_type_klass option"
        @data_type_klass =
          if [Symbol, String].includes? opts[:data_type_klass].class
            opts[:data_type_klass].to_s.classify.constantize
          else
            opts[:data_type_klass]
          end
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
        raise "Invalid field #{name}" if field_definitions[name] == nil
        return @child_builders[name] if @child_builders[name].present?

        data_type_klass = field_definitions[name][:data_type]
        child_builder = Builder.new(
          data_type_klass: data_type_klass,
          ctx: @ctx,
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

      private

      def field_definitions
        data_type_klass.field_definitions
      end

    end
  end
end
