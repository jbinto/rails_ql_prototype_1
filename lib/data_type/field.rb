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

        validate_args!
      end

      def data_type_args
        @data_type_args ||= @prototype_data_type.args.symbolize_keys
      end

      def validate_args!
        required_args = @field_definition.required_args.symbolize_keys
        arg_whitelist = @field_definition.arg_whitelist
        arg_keys = data_type_args.keys

        unless (forbidden_args = arg_keys - arg_whitelist).empty?
          raise ForbiddenArg, "Invalid args: #{forbidden_args} for #{@name}"
        end

        unless (missing_required_args = required_args.keys - arg_keys).empty?
          raise(
            ArgMissing,
            "Missing required args: #{missing_required_args} for #{@name}"
          )
        end

        data_type_args.each do |k, v|
        end
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
            data_type_args,
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

        return [] if models.nil?
        return models.is_a?(Array) ? models : [models]
      end

      def resolve_models_and_dup_data_type!
        models = resolved_models

        if models.blank?
          if nullable? || !singular?
            return @data_types = []
          else
            raise NullField, @name
          end

        end

        @data_types = models.map do |model|
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
