require_relative "./type_builder_collection.rb"
require_relative "./field_collection_builder.rb"

module RailsQL
  module Builder
    class TypeBuilder
      attr_reader(
        :type_klass,
        :child_type_builders,
        :variables,
        :fragments
      )

      def initialize(opts)
        opts = {
          ctx: nil,
          root: nil,
          # The type the builder will instantiate in Builder#type
          type_klass: nil,
          # The anonomous input object from the field definition for the field
          # this builder is constructing. Not used for builders where the type
          # is being used as an argument to a field.
          args_definition: nil,
          # is_input is true if this type is used as an argument to a field
          # (input).
          # is_input is false if this type is used as a field (output).
          is_input: false,
          model: nil
        }.merge opts
        if opts[:type_klass].blank?
          raise "requires a :type_klass option"
        end
        @type_klass = KlassFactory.find opts[:type_klass]
        @args_definition = opts[:args_definition]
        @ctx = opts[:ctx]
        @root = opts[:root]
        @is_input = opts[:is_input]
        @model = opts[:model]
        @unresolved_variables = {}
        @unresolved_fragments = []

        @arg_type_builders = TypeBuilderCollection.new(
          field_definitions: @args_definition.field_definitions
        )
        @child_type_builders = TypeBuilderCollection.new(
          field_definitions: type_klass.field_definitions
        )
      end

      def type
        return @type if @type.present?
        @type = type_klass.new(
          args: @arg_type_builders.types,
          ctx: @ctx,
          root: @root
        )
        @type.model = @model if @is_input
        # add child fields
        field_collection_builder = FieldCollectionBuilder.new(
          parent_type: @type,
          child_type_builders: @child_type_builders
        )
        @type.fields = field_collection_builder.fields
        return @type
      end

      def add_child_builder!(name:)
        @child_type_builders.add_builder! name: name
      rescue Exception => e
        raise e, "#{e.message} on #{@type_klass} fields", e.backtrace
      end

      def add_arg_builder!(name:, model:)
        @arg_type_builders.add_builder! name: name, model: model
      rescue Exception => e
        raise e, "#{e.message} on #{@type_klass} args", e.backtrace
      end

      def add_variable!(argument_name:, variable_name:, variable_type_name:)
        valid = @args_definition.valid_child_type?(
          name: argument_name,
          type_name: variable_type_name
        )
        unless valid
          msg = <<-ERROR.strip_heredoc
            #{variable_name} is of the wrong type #{variable_type_name} for
            #{argument_name} on #{type_klass.type_definition.type_name}"
          ERROR
          raise ArgTypeError, msg
        end
        @variables[argument_name] = variable_name
      end

      def add_fragment!(name:)
        @fragments << name
      end

      def resolve_variables!
      end

      def resolve_fragments!
        # TODO: error out if the type of the fragment does not match the type of this type_klass
      end

    end
  end
end
