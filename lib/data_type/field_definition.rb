module RailsQL
  module DataType
    class FieldDefinition
      attr_reader :data_type, :args, :description, :nullable, :query, :resolve

      def initialize(name, opts)
        if opts[:data_type].blank?
          raise "Invalid field #{name}: requires a :data_type option"
        end

        @name = name

        defaults = {
          data_type: opts[:data_type] || name,
          description: nil,
          args: [],
          nullable: true,
          resolve: nil,
          query: nil
        }
        defaults.merge(opts.slice *defaults.keys).each do |key, value|
          instance_variable_set "@#{key}", value
        end
      end

      def add_read_permission(lambda)
        @read_permission = lambda
      end

      def read_permission
        @read_permission || ->{false}
      end

    end
  end
end