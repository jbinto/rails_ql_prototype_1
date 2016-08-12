require_relative "./kind.rb"
require_relative "../field/field_definition_collection.rb"

module RailsQL
  class Type
    module ClassMethods
      def type_name(*args)
        getter_and_setter_for(:type_name, args) do |type_name|
          @type_name = type_name.try :strip
        end
      end

      def description(*args)
        getter_and_setter_for(:description, args) do |description|
          @description = description.strip_heredoc
        end
      end

      # Excludes the type from the schema in the introspection API.
      # (e.g. for wrapping modifier types, anon. input objects)
      def anonymous(*args)
        @anonymous ||= false
        getter_and_setter_for(:anonymous, args) do |anonymous|
          @anonymous = anonymous
        end
      end

      def kind(*args)
        @kind ||= :object
        getter_and_setter_for(:kind, args) do |kind|
          kind = args.first
          kind_values = Kind.enum_values.map{|v| v.to_s.downcase.to_sym}
          if kind_values.include? kind
            @kind = kind
          else
            raise <<-eos.strip_heredoc
              #{kind} is not a valid kind. Must be one of
              #{kind_values.join ", "}
            eos
          end
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
          name: @type_name || to_s,
          kind: @kind || :object,
          enum_values: @enum_values || {},
          description: @description,
        )
      end

      def self.valid_fragment_type_names
        [type_definition.type_name]
      end

      def type?
        true
      end

      def modifier_type?
        false
      end

      def directive?
        false
      end

      def union?
        false
      end

      # TODO add specs
      def valid_child_type?(name:, type_name:)
        child_klass = field_definitions[name].try(:type_klass)
        return false if child_klass.nil?
        return child_klass.type_definition.name.to_s == type_name
      end

      def initial_query(initial_query)
        @initial_query = initial_query
      end

      def get_initial_query
        @initial_query
      end

      def field_definitions
        @field_definitions ||= Field::FieldDefinitionCollection.new
      end

      def can(operations, opts)
        field_definitions.add_permissions(operations, opts)
      rescue Exception => e
        raise e, "#{e.message} on #{self}", e.backtrace
      end

      def can?(action, field_name, on:)
        field_definitions[field_name].can action, on: on
      end

      def field(name, opts)
        field_definitions.add_field_definition(name, opts)
      end

      private

      def getter_and_setter_for(attr_sym, args)
        if args.length == 1
          yield args.first
        elsif args.length == 0
          instance_variable_get :"@#{attr_sym}"
        else
          raise "#{attr_sym} takes 0 or 1 argument"
        end
      end

    end
  end
end
