module RailsQL
  module Builder
    class DirectiveBuilder
      attr_accessor(
        :name, :arg_builder
      )

      def initialize(type_klass:)
        @type_klass = ::RailsQL::Type::KlassFactory.find type_klass
        @arg_type_builder = TypeBuilder.new(
          type_klass: @type_klass.args_definition
        )
      end

    end
  end
end
