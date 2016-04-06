module RailsQL
  module DataType
    class Base
      attr_reader :args

      @field_definitions = HashWithIndifferentAccess.new

      def initialize(opts)
        opts = {
          fields: {},
          args: {}
        }.merge opts
        @fields = HashWithIndifferentAccess.new(opts[:fields]).freeze
        @args = HashWithIndifferentAccess.new(opts[:args]).freeze
      end

      def query
        initial_query = self.class.call_initial_query
        fields.reduce(initial_query) do |query, name, child_data_type|
          definition = self.class.field_definitions[name]
          next unless definition[:query].present?
          definition[:query].call(
            child_data_type.args,
            query,
            child_data_type.query
          )
        end
      end

      def resolve
      end

      class << self
        attr_reader :field_definitions

        def initial_query(initial_query)
          @initial_query = initial_query
        end

        def call_initial_query
          return @initial_query.call
        end
      end
    end

  end
end


