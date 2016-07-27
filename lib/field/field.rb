module RailsQL
  module Field
    class Field
      attr_reader :prototype_type, :types, :field_definition
      attr_accessor :parent_type

      def initialize(opts)
        @field_definition = opts[:field_definition]
        @parent_type = opts[:parent_type]
        @prototype_type = opts[:type]
        @name = opts[:name]

        validate_args!
      end

      def resolve_child_types!(parent_type:)
        @parent_type = parent_type
        resolve_models_and_dup_type!
        types.each &:resolve_child_types!
      end

      def inject_json(parent_json:, key:)
        child_json = types.as_json
        parent_json.merge(
          key => field.singular? ? child_json.first : child_json
        )
      end

      def type_args
        @type_args ||= @prototype_type.args.symbolize_keys
      end

      def validate_args!
        return if type_args.empty?

        @field_definition.args.validate_input_args! type_args
      end

      def nullable?
        @field_definition.nullable?
      end

      def singular?
        @field_definition.singular?
      end

      def appended_parent_query
        @field_definition.append_to_query(
          parent_type: @parent_type,
          args: type_args,
          child_query: @prototype_type.query
        )
      end

      def resolved_models
        models = @field_definition.resolve(
          parent_type: @parent_type,
          args: type_args,
          child_query: @prototype_type.query
        )

        return [] if models.nil?
        return models.is_a?(Array) ? models : [models]
      end

      def resolve_models_and_dup_type!
        models = resolved_models

        if models.blank?
          if nullable? || !singular?
            return @types = []
          else
            raise NullField, @name
          end

        end

        @types = dup_type! models
      end

      def dup_type!(models)
        models.map do |model|
          type = prototype_type.deep_dup
          type.fields = prototype_type.fields.deep_dup
          type.model = model
          type
        end
      end

      def has_read_permission?
        @field_definition.read_permissions.any? do |permission|
          @parent_type.instance_exec &permission
        end
      end

      def child_field_collections
        populated_types.map(&:field_collection)
      end
    end
  end
end
