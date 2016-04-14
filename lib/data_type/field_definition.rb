module RailsQL
  module DataType
    class FieldDefinition
      attr_reader :data_type, :args, :description, :nullable, :query, :resolve

      def initialize(name, opts)
        @name = name
        @read_permissions = []

        defaults = {
          data_type: "#{name.to_s.singularize.classify}DataType",
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
        @read_permissions << lambda
      end

      def read_permissions
        if @read_permissions.present?
          @read_permissions.clone
        else
          [->{false}]
        end
      end

    end
  end
end