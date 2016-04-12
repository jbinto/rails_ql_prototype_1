module RailsQL
  module DataType
    class Field

      def initialize(opts)
        @field_definition = opts[:field_definition]
        @parent_data_type = opts[:parent_data_type]
        @data_type = opts[:data_type]
        @name = opts[:name]
      end

      def add_to_parent_query!
        if @field_definition.query.present?
          @parent_data_type.instance_exec(@data_type.args, @data_type.query, &@field_definition.query)
        else
          @parent_data_type.query
        end
      end

      def resolve!
        @data_type.model =
          if @field_definition.resolve.present?
            # @parent_data_type.instance_eval(&@field_definition.resolve,
            #   @data_type.args,
            #   @data_type.query
            # )
          elsif @parent_data_type.respond_to? @name
            @parent_data_type.send @name
          else
            @parent_data_type.model.send @name
          end
        @data_type.resolve_child_data_types!
      end

      def has_read_permission?
        permission = @field_definition.read_permission
        @parent_data_type.instance_eval &permission
      end

    end
  end
end