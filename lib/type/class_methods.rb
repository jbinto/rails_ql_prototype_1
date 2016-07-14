module RailsQL
  class Type
    module ClassMethods
      def type_name(next_name)
        @name = next_name.try :strip
      end

      def description(description=nil)
        @description = description.try(:gsub, /\n\s+/, "\n").try :strip
      end

      def kind(kind)
        kind_values = Kind.enum_values
        if kind_values.include? kind
          @kind = kind
        else
          raise <<-eos.gsub(/[\s\n]+/, " ")
            #{kind} is not a valid kind. Must be one of
            #{kind_values.join ", "}
          eos
        end
      end

      def enum_values(*enum_values, opts)
        if opts.is_a? Symbol
          enum_values << opts
          opts = {}
        end
        opts = {
          is_deprecated: false,
          deprecation_reason: nil
        }.merge opts
        @enum_values = (@enum_values || {}).merge(
          Hash[enum_values.map{|value|
            [value, OpenStruct.new(opts.merge(name: value))]
          }]
        )
      end

      def type_definition
        return OpenStruct.new(
          name: @name || to_s,
          kind: @kind || :OBJECT,
          enum_values: @enum_values || {},
          description: @description,
        )
      end

      def data_type?
        true
      end

      def initial_query(initial_query)
        @initial_query = initial_query
      end

      def get_initial_query
        @initial_query
      end

      def field_definitions
        @field_definitions = FieldDefinitionCollection.new FieldDefinition
      end

      def can(operations, opts)
        @field_definitions.add_permissions(operations, opts)
      end

      # Adds a FieldDefinition to the data type
      #
      #   class UserType < RailsQL::Type::Type
      #
      #     field(:email,
      #       data_type: RailsQL::Type::String
      #     )
      #   end
      #
      # Options:
      # * <tt>:data_type</tt> - Specifies the data_type
      # * <tt>:description</tt> - A description of the field
      # * <tt>:accessible_args</tt> - Arguments that can be passed to the resolve method
      # * <tt>:nullable</tt> -
      def field(name, opts)
        @field_definitions.add_field_definition(name, opts)
      end

      alias_method :has_one, :field

      def has_many(name, opts)
        @field_definitions.add_plural_field_definition(name, opts)
      end

    end
  end
end
