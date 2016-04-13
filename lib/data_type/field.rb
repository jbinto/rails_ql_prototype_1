module RailsQL
  module DataType
    class Field
      attr_reader :data_type

      def initialize(opts)
        @field_definition = opts[:field_definition]
        @parent_data_type = opts[:parent_data_type]
        @data_type = opts[:data_type]
        @name = opts[:name]
      end

      def appended_parent_query
        if @field_definition.query.present?
          @parent_data_type.instance_exec(
            @data_type.args,
            @data_type.query,
            &@field_definition.query
          )
        else
          @parent_data_type.query
        end
      end

      def resolved_model
        if @field_definition.resolve.present?
          @parent_data_type.instance_exec(
            @data_type.args,
            @data_type.query,
            &@field_definition.resolve
          )
        elsif @parent_data_type.respond_to? @name
          @parent_data_type.send @name
        else
          @parent_data_type.model.send @name
        end
      end

      def has_read_permission?
        @field_definition.read_permissions.any? do |permission|
          @parent_data_type.instance_eval &permission
        end
      end

    end
  end
end