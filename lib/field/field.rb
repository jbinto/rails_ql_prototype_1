module RailsQL
  module Field
    class Field
      attr_reader :prototype_type, :types, :field_definition. :args_type
      attr_accessor :parent_type

      delegate(
        :nullable?,
        :singular?,
        to: :field_definition
      )

      def initialize(opts)
        @field_definition = opts[:field_definition]
        @parent_type = opts[:parent_type]
        @prototype_type = opts[:type]
        @args_type = opts[:args_type]
        @name = opts[:name]
      end

      def resolve_child_types!(parent_type:)
        @parent_type = parent_type
        resolve_models_and_dup_type!
        types.each &:resolve_child_types!
      end

      def appended_parent_query
        @prototype_type.build_query!
        @field_definition.append_to_query(
          parent_type: @parent_type,
          args_type: args_type.as_json,
          child_query: @prototype_type.query
        )
      end

      def resolved_models
        models = @field_definition.resolve(
          parent_type: @parent_type,
          args_type: args_type.as_json,
          child_query: @prototype_type.query
        )

        return [] if models.nil?
        return models.is_a?(Array) ? models : [models]
      end

      def can?(action)
        @field_definition.permissions[action].any? do |permission|
          @parent_type.instance_exec &permission
        end
      end

      def child_field_collections
        populated_types.map(&:field_collection)
      end

      private

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

    end
  end
end
