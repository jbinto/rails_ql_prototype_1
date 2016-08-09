require_relative "../type/klass_factory.rb"

module RailsQL
  module Builder
    class TypeBuilder
      attr_accessor(
        :name,
        :aliased_as,
        :directive_name,
        :first_directive_builder,
        :unioned_type_klass
      )

      attr_reader(
        :root,
        :arg_type_builder,
        :is_input,
        :is_directive,
        :child_builders,
        :fragment_builders,
        :variables
      )

      def initialize(
        # The name of the field or nil for anonomous input objects and roots
        name: nil,
        aliased_as: nil,
        root: false,
        arg_type_builder: nil,
        # is_input is true if this type is used as an argument to a field
        # (input).
        # is_input is false if this type is used as a field (output).
        is_input: false,
        model: nil
      )
        @name = name
        @aliased_as = aliased_as
        @root = root
        @arg_type_builder = arg_type_builder
        @is_input = is_input
        @model = model
        @child_builders = []
        @fragment_builders = []
        @variables = {}
      end

      def is_input?
        return @is_input
      end

      def directive?
        directive_name.present?
      end

      def add_variable!(argument_name:, variable_name:)
        @variables[argument_name] = variable_name
      end

      def add_fragment_builder!(fragment_builder)
        @fragment_builders << fragment_builder
      end

      def last_directive_builder
        if directive?
          # each directive builder can only have one child directive builder
          @child_builders.select(&:directive?).first.try :last_directive_builder
        else
          first_directive_builder.try :last_directive_builder
        end
      end

      # TODO: directives and fragments

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
      #         #{argument_name} on #{type_klass.type_name}"
      #       ERROR
      #       raise ArgTypeError, msg
      #     end
      #   end
      # end

    #   def resolve_fragments!(type_klass)
    #     @fragment_builders.each do |name, fragment_builder|
    #       if fragment_builder.type_builder.blank?
    #         raise(InvalidFragment,
    #           "Fragment #{fragment_builder.fragment_name} is not defined"
    #         )
    #       end
    #       fragment_klass = fragment_builder.type_klass
    #       # Union fragments get applied to the child builders for the applicable
    #       # type inside the Union unless they are requesting the __typename meta
    #       # field
          if type_klass.is_a?(RailsQL::Union) && fragment_klass != type_klass
    #         # ap "UNION"
    #         # ap fragment_klass
    #         # ap type_klass
            fragment_type_name = fragment_klass.type_name
            child_builder = add_child_builder! fragment_type_name
            child_builder.add_fragment_builder! builder
    #       # Non-union types simply add the fragment to the builder for later
    #       # resolution (see TypeBuilder#resolve_fragments!)
    #       elsif fragment_klass == type_klass
    #         resolve_fragment! fragment_builder
    #       # error out if the type of the fragment is incompatible with the
    #       # type of this builder
    #       else
    #         msg = <<-ERROR.strip_heredoc.gsub("\n", "").strip
    #           Fragment is defined on #{fragment_type_name}
    #           but fragment spread is on an incompatible type
    #           (#{type_klass.type_name})
    #         ERROR
    #         raise InvalidFragment, msg
    #       end
    #     end
    #     return self
    #   end
    #
    #   private
    #
    #   def resolve_fragment!(fragment_builder)
    #     # TODO: fragments on interface types
    #     begin
    #       fragment_builder.child_builders do |name, child_builder|
    #         @child_builders.add_existing_builder!(
    #           name: name,
    #           type_builder: child_builder
    #         )
    #       end
    #     rescue Exception => e
    #       msg = <<-ERROR.strip_heredoc
    #         #{e.message} on #{@type_klass} in fragment
    #         #{fragment_builder.fragment_name}
    #       ERROR
    #       raise e, msg, e.backtrace
    #     end
    #   end
    #

    end
  end
end
