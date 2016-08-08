module RailsQL
  module Builder
    class TypeFactory

      def self.build!(variable_builders:, **build_args)
        self.new(variable_builders: variable_builders).build! build_args
      end

      def initialize(variable_builders:)
        @variable_builders = variable_builders
      end

      # Recursively build and return an instance of `type_klass` and it's
      # children based on the builder, field definition and ctx.
      def build!(field_definition: nil, type_klass:, builder:, ctx:)
        if builder.is_a? FragmentBuilder
          validate_fragment_builder!(
            type_klass: type_klass,
            builder: builder
          )
        end
        # Build ctx and opts to be passed to the type klass constructor
        child_ctx = ctx.merge(field_definition.try(child_ctx) || {})
        opts = {
          ctx: child_ctx,
          root: builder.try(:root) || false,
          field_definition: field_definition,
          field_alias: @field_alias || @name,
        }
        # Fields have an arg type builder. Recursively build the fields
        # arguments and their nested input objects (if any exist).
        if builder.try(:arg_type_builder).present?
          opts[:args_type] = build!(
            type_klass: field_definition.args_type_klass,
            builder: builder.arg_type_builder,
            ctx: child_ctx
          )
        end
        # Build the children for modifier types (ie. lists and non-nullable)
        if type_klass.responds_to? :of_type
          opts = opts.merge build_modifier_type_opts!(
            type_klass: type_klass,
            builder: builder,
            child_ctx: child_ctx
          )
        # Build fields for non-modifier types
        else
          opts[:field_types] = build_fields_or_args!(
            type_klass: type_klass,
            builder: builder,
            child_ctx: child_ctx
          )
        end
        # Once recursion is complete instantiate and return the type klass
        type = type_klass.new opts
        type.model = builder.try :model
        return type
      end

      private

      def validate_fragment_builder!(
        type_klass: type_klass,
        builder: builder
      )
        if builder.type_builder.blank?
          raise(InvalidFragment,
            "Fragment #{fragment_builder.fragment_name} is not defined"
          )
        end
        if builder.fragment_defined_on != type_klass.type_definition.type_name
          msg = <<-ERROR.strip_heredoc.gsub("\n", "").strip
            Fragment is defined on #{builder.fragment_defined_on}
            but fragment spread is on an incompatible type
            (#{type_klass.type_definition.type_name})
          ERROR
          raise InvalidFragment, msg
        end
      end

      def build_modifier_type_opts!(
        type_klass:,
        builder:,
        child_ctx:
      )
        opts = {}
        # build the list of types for input lists
        if type_klass.is_a? RailsQL::Type::List && builder.is_input?
          list = builder.child_builders.map do |child_builder|
            build!(
              type_klass: type_klass.of_type,
              builder: child_builder,
              ctx: child_ctx
            )
          end
          opts[:list_of_resolved_types] = list
        # Create the modified type for Non-nullable args, non-nullable fields
        # and field lists
        else
          opts[:modified_type] = build!(
            type_klass: type_klass.of_type,
            builder: OpenStruct.new(
              is_input: builder.is_input,
              child_builders: []
            ),
            ctx: child_ctx
          )
        end
        return opts
      end

      def build_fields_or_args!(
        type_klass:,
        builder:,
        child_ctx:,
      )
        fields = {}
        # Inject variable builders into the list of args (do nothing for fields)
        child_builders = builder.child_builders.clone
        builder.variables.each do |argument_name, variable_name|
          if @variable_builders[argument_name].blank?
            raise MissingVariableDefinition, <<-ERROR
              Variable not defined in operation: #{variable_name}
            ERROR
          end
          variable_builder = @variable_builders[argument_name].dup
          variable_builder.name = argument_name
          variable_builder.aliased_as = argument_name
          child_builders << variable_builder
        end
        # Build fields (or args)
        # TODO: field merging should go here
        # Basically take 2 or more type builders, compare them and then
        # combine them and their child type builders recursively into new objects
        child_builders.each do |child_builder|
          field_definition = type_klass.field_definitions[child_builder.name]
          if field_definition.blank?
            raise "Invalid key #{type_builder.name}"
          end

          fields[child_builder.aliased_as] = build!(
            field_definition: field_definition,
            type_klass: field_definition.type_klass,
            builder: child_builder,
            ctx: child_ctx
          )
        end
        return fields
      end

    end
  end
end
