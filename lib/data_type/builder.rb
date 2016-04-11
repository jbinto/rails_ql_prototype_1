module RailsQL
  module DataType
    class Builder
      def initialize(opts)
        @data_type_name = opts[:data_type_name]
        @child_builders = {}
        @context = opts[:context]
        @root = opts[:root]
        @args = {}
      end

      def data_type_klass
        @data_type_klass ||= @data_type_name.classify.constantize
      end

      def data_type
        # if [Symbol, String].includes? opts[:data_type].class
        #   opts[:data_type] = opts[:data_type].to_s.classify.constantize
        # end
        @data_type ||= data_type_klass.new(
          args: @args,
          fields: @child_builders.reduce({}) {|fields, type, builder|
            ap type
            fields[type] = builder.data_type
          },
          context: @context,
          root: @root
        )
      end

      # idempotent
      def add_child_builder(name)
        raise "Invalid field #{name}" if field_definitions[name] == nil
        return @child_builders[name] if @child_builders[name].present?

        data_type_name = field_definitions[name][:data_type]
        child_builder = Builder.new(
          data_type_name: data_type_name,
          context: @context,
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
