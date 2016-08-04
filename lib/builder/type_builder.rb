require_relative "./type_builder_collection.rb"
require_relative "./field_collection_builder.rb"
require_relative "../type/klass_factory.rb"

module RailsQL
  module Builder
    class TypeBuilder
      attr_reader(
        :type_klass,
        :child_type_builders,
        :variables,
        :fragments,
      )

      attr_accessor :field_alias

      def initialize(
          # The type the builder will instantiate in Builder#type
          type_klass:
          # TODO: move ctx out of the type builder (type builders are re-usable)
          ctx: nil,
          root: false,
          # The anonomous input object from the field definition for the field
          # this builder is constructing. Not used for builders where the type
          # is being used as an argument to a field.
          args_type_klass: nil,
          # is_input is true if this type is used as an argument to a field
          # (input).
          # is_input is false if this type is used as a field (output).
          is_input: false,
          model: nil,
          field_definition: nil
        )
        @type_klass = ::RailsQL::Type::KlassFactory.find type_klass
        @ctx = ctx
        @root = root
        @args_type_klass = args_type_klass
        @is_input = is_input
        @model = model
        @field_definition = field_definition
        @unresolved_variables = {}
        @directive_builders = []
        @fragment_builders = []

        unless @is_input
          @arg_type_builder = TypeBuilder.new(
            type_klass: @args_type_klass,
            ctx: @ctx,
            is_input: true
          )
        end
        @child_type_builders = TypeBuilderCollection.new(
          field_definitions: @type_klass.field_definitions
        )
      end

      def is_input?
        return @is_input
      end

      def field_name
        @field_definition.name
      end

      # Builds and returns an instance of type_klass. Can be called multiple
      # times to build multiple instances of the Type.
      def build_type!
        type = @type_klass.new(
          ctx: @ctx,
          root: @root,
          field_definition: @field_definition,
          field_alias: @field_alias || @field_name,
          args_type: @arg_type_builder.build_type!,
          field_types: @child_type_builders.build_types!
        )
        type.model = @model if @is_input
        # add child fields
        return type
      end

      def add_child_builder!(opts)
        annotate_exceptions do
          @child_type_builders.create_and_add_builder! opts
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

      def add_variable!(argument_name:, variable_name:)
        @variables[argument_name] = variable_name
      end

      def add_fragment_builder!(fragment_builder)
        @fragment_builders << fragment_builder
      end

      # def add_directive_builder!(directive_builder)
      #   raise "TODO: move directives stuff to directive builders"
      #   @directive_builders << directive_builder
      # end
      #
      # def resolve_variables!(variable_definitions:, variable_values:)
      #   @variables.each do |argument_name, variable_name|
      #     unless variable_definitions.include? variable_name
      #       raise(RailsQL::UndefinedVariable,
      #         "#{name} was not defined as a variable in the operation"
      #       )
      #     end
      #     valid = @args_type_klass.valid_child_type?(
      #       name: argument_name,
      #       type_name: variable_type_name
      #     )
      #     unless valid
      #       msg = <<-ERROR.strip_heredoc
      #         #{variable_name} is of the wrong type #{variable_type_name} for
      #         #{argument_name} on #{type_klass.type_definition.type_name}"
      #       ERROR
      #       raise ArgTypeError, msg
      #     end
      #   end
      # end

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
            # ap "UNION"
            # ap fragment_klass
            # ap type_klass
            fragment_type_name = fragment_klass.type_name
            child_builder = add_child_builder! fragment_type_name
            child_builder.add_fragment_builder! builder
          # Non-union types simply add the fragment to the builder for later
          # resolution (see TypeBuilder#resolve_fragments!)
          elsif fragment_klass == type_klass
            resolve_fragment! fragment_builder
          # error out if the type of the fragment is incompatible with the
          # type of this builder
          else
            msg = <<-ERROR.strip_heredoc.gsub("\n", "").strip
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
