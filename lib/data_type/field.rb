module RailsQL
  module DataType
    class Field
      attr_reader :prototype_data_type, :data_types, :field_definition
      attr_accessor :parent_data_type

      def initialize(opts)
        @field_definition = opts[:field_definition]
        @parent_data_type = opts[:parent_data_type]
        @prototype_data_type = opts[:data_type]
        @name = opts[:name]
      end

      def nullable?
        @field_definition.nullable?
      end

      def singular?
        @field_definition.singular?
      end

      def appended_parent_query
        if @field_definition.query.present?
          @parent_data_type.instance_exec(
            @prototype_data_type.args,
            @prototype_data_type.query,
            &@field_definition.query
          )
        else
          @parent_data_type.query
        end
      end

      def resolved_models
        models =
          if @field_definition.resolve.present?
            @parent_data_type.instance_exec(
              @prototype_data_type.args,
              @prototype_data_type.query,
              &@field_definition.resolve
            )
          elsif @parent_data_type.respond_to? @name
            @parent_data_type.send @name
          else
            @parent_data_type.model.try @name
          end
        return models.is_a?(Array) ? models : [models]
      end

      def resolve_models_and_dup_data_type!
        @data_types = resolved_models.map do |model|
          data_type = prototype_data_type.deep_dup
          data_type.fields = prototype_data_type.fields.deep_dup
          data_type.model = model
          data_type
        end
      end

      def has_read_permission?
        @field_definition.read_permissions.any? do |permission|
          @parent_data_type.instance_exec &permission
        end
      end

    end
  end
end
