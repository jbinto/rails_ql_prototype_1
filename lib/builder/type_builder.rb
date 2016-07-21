require_relative "./type_builder_collection.rb"
require_relative "./field_collection_builder.rb"

module RailsQL
  module Builder
    class TypeBuilder
      attr_reader(
        :type_klass,
        :child_type_builders,
        :variables,
        :fragments,
        :is_input,
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
          model: nil,
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
        @fragment_name = opts[:fragment_name]
        @unresolved_variables = {}
        @unresolved_fragments = []

        @arg_type_builder = TypeBuilder.new(
          type_klass: @args_definition
        )
        @child_type_builders = TypeBuilderCollection.new(
          field_definitions: type_klass.field_definitions
        )
      end

      # Builds and returns an instance of type_klass. Can be called multiple
      # times to build multiple instances of the Type.
      def build_type!
        type = type_klass.new(
          args: @arg_type_builder.build_type!,
          ctx: @ctx,
          root: @root
        )
        type.model = @model if @is_input
        # add child fields
        field_collection_builder = FieldCollectionBuilder.new(
          parent_type: type,
          child_type_builders: @child_type_builders
        )
        type.fields = field_collection_builder.build_fields!
        return type
      end

      def add_child_builder!(name:, model: nil)
        annotate_exceptions do
          @child_type_builders.create_and_add_builder! name: name, model: model
        end
      end

      def add_arg_builder!(name:, model:)
        annotate_exceptions do
          @arg_type_builder.add_child_builder! name: name, model: model
        end
      end

      def annotate_exceptions
        yield
      rescue Exception => e
        if @type_klass.anonomous
          raise e
        else
          raise e, "#{e.message} on #{@type_klass}", e.backtrace
        end
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

      def add_fragment_builder!(fragment_builder)
        @fragment_builders << builder
      end

      def resolve_variables!
        # TODO!
        return self
      end

      def resolve_fragments!
        @fragment_builders.each do |name, fragment_builder|
          if fragment_builder.type_builder.blank?
            raise(InvalidFragment,
              "Fragment #{fragment_builder.fragment_name} is not defined"
            )
          end
          fragment_klass = fragment_builder.type_klass
          # Union fragments get applied to the child builders for the applicable
          # type inside the Union unless they are requesting the __typename meta
          # field
          if type_klass.is_a?(RailsQL::Union) && fragment_klass != type_klass
            fragment_type_name = fragment_klass.type_definition.type_name
            child_builder = add_child_builder! fragment_type_name
            child_builder.add_fragment_builder! builder
          # Non-union types simply add the fragment to the builder for later
          # resolution (see TypeBuilder#resolve_fragments!)
          elsif fragment_klass == type_klass
            resolve_fragment! fragment_builder
          # error out if the type of the fragment is incompatible with the type of
          # this builder
          else
            msg = <<-ERROR.strip_heredoc
              Fragment is defined on #{fragment_type_name}
              but fragment spread is on an incompatible type
              (#{type_klass.type_definition.type_name})
            ERROR
            raise InvalidFragment, msg
          end
        end
        return self
      end

      def resolve_fragment!(fragment_builder)
        # TODO: fragments on interface types
        begin
          fragment_builder.child_type_builders do |name, child_builder|
            @child_type_builders.add_existing_builder!(
              name: name,
              type_builder: child_builder
            )
          end
        rescue Exception => e
          msg = <<-ERROR.strip_heredoc
            #{e.message} on #{@type_klass} in fragment
            #{fragment_builder.fragment_name}
          ERROR
          raise e, msg, e.backtrace
        end
      end

    end
  end
end