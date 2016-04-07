module RailsQL
  module DataType
    class Builder
      attr_reader :data_type_klass

      def initialize(data_type_klass)
        @data_type_klass = data_type_klass
        @child_builders = {}
        @args = {}
      end

      def data_type
        @data_type ||= data_type_klass.new(
          args: @args,
          fields: @child_builders.map {|type, builder| builder.data_type }
        )
      end

      # idempotent
      def add_child_builder(name)
        raise "Invalid field #{name}" if field_definitions[name] == nil
        return @child_builders[name] if @child_builders[name].present?
        child_klass = field_definitions[name][:data_type]

        child_builder = Builder.new(child_klass)
        @child_builders[name] = child_builder
        return child_builder
      end

      def child_builders
        Hash.new @child_builders
      end

      def add_arg(name, value)
        @args[name.to_s] = value
      end

      def args
        Hash.new @args
      end

      private

      def field_definitions
        data_type_klass.field_definitions
      end

    end
  end
end
