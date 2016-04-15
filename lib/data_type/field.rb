module RailsQL
  module DataType
    class Field
      attr_reader :prototype_data_type, :data_types

      def initialize(opts)
        @field_definition = opts[:field_definition]
        @parent_prototype_data_type = opts[:parent_data_type]
        @prototype_data_type = opts[:data_type]
        @singular = opts[:singular]
        @name = opts[:name]
      end

      def singular?
        @singular
      end

      def appended_parent_query
        if @field_definition.query.present?
          @parent_prototype_data_type.instance_exec(
            @prototype_data_type.args,
            @prototype_data_type.query,
            &@field_definition.query
          )
        else
          @parent_prototype_data_type.query
        end
      end

      def resolved_models(parent_data_type)
        if @field_definition.resolve.present?
          parent_data_type.instance_exec(
            @prototype_data_type.args,
            @prototype_data_type.query,
            &@field_definition.resolve
          )
        elsif parent_data_type.respond_to? @name
          parent_data_type.send @name
        else
          parent_data_type.model.send @name
        end
      end

      def dup_data_types_for!(parent_data_type)
        field.data_types = resolved_models(parent_data_type).map do |model|
          data_type = prototype_data_type.deep_dup
          child_data_type.model = model
          child_data_type
        end
      end

      def has_read_permission?
        @field_definition.read_permissions.any? do |permission|
          @parent_prototype_data_type.instance_exec &permission
        end
      end

    end
  end
end
