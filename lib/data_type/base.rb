module RailsQL
  module DataType
    class Base
      PRIMITIVE_DATA_TYPES = %w(RailsQL::DataType::String)
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
        @fields.each do |name, data_type|
          # child_resolve = data_type[:resolve] || ->{
          #   # call the method on the data_type if the user defined it there,
          #   # else directly call the method on the model
          #   (self.respond_to?(name) ? self : model).send name
          # }
          data_type.model = data_type[:resolve].call()
        end
      end

      def to_h
        @fields.map do |name, data_type|
          {
            name => data_type.to_h
          }
        end
      end

      def to_json
        @fields.map do |name, data_type|
          {
            name => data_type.to_json
          }
        end
      end

      class << self
        attr_reader :field_definitions

        def initial_query(initial_query)
          @initial_query = initial_query
        end

        def call_initial_query
          return @initial_query.call
        end

        # Adds a field definition to the data type
        #
        #   class UserType < RailsQL::DataType::Base
        #
        #     field(:email,
        #       data_type: RailsQL::DataType::String
        #     )
        #   end
        #
        # Options:
        # * <tt>:data_type</tt> - Specifies the primtive data_type
        # * <tt>:description</tt> - A description of the field
        # * <tt>:args</tt> - Arguments to be passed to the resolve method
        # * <tt>:nullable</tt> -
        def field(name, opts={})
          # Overwrite resolve and query with nil. These options are not exposed
          # for non-association fields. Use .has_many or .has_one fo
          # associations.
          opts = opts.merge(
            resolve: nil,
            query: nil
          )

          unless PRIMITIVE_DATA_TYPES.include? opts[:data_type].to_s
            raise "Invalid field #{to_s}##{name}: #{
              opts[:data_type]
            } is not a valid data_type"
          end

          add_field_definition name, opts
        end

        private

        def add_field_definition(name, opts={})
          opts = {
            data_type: nil,
            description: nil,
            args: [],
            nullable: true,
            resolve: nil,
            query: nil
          }.merge opts

          if opts[:data_type].blank?
            raise "Invalid field #{to_s}##{name}: requires a :data_type option"
          end

          # add to field definitions
          defaults = {
            data_type: opts[:data_type] || name,
            args: [],
            resolve: ->(args, child_query) { model.send(data_type.to_s) },
            query: nil
          }
          (field_definitions[name] ||= defaults).merge! opts
        end

        alias_method :has_many, :add_field_definition
        alias_method :has_one, :add_field_definition

      end
    end

  end
end


