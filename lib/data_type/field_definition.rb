module RailsQL
  module DataType
    class FieldDefinition
      attr_reader :data_type, :args, :description, :nullable

      def initialize(name, opts)
        if opts[:data_type].blank?
          raise "Invalid field #{name}: requires a :data_type option"
        end

        @name = name

        defaults = {
          data_type: opts[:data_type] || name,
          description: nil,
          args: [],
          nullable: true,
          # resolve: ->(args) {
            # if data_type.respond_to? :da
            # model.send(data_type.to_s)
          # },
          resolve: nil,
          query: nil
        }
        defaults.merge(opts.slice *defaults.keys).each do |key, value|
          instance_variable_set "@#{key}", value
        end
      end

      def add_to_parent_query(opts)
        [
          :parent_query,
          :args,
          :child_query
        ].each do |k, v|
          raise "query requires a :#{k} option" unless opts.include? k
        end

        if @query.present?
          @query.call(
            opts[:args],
            opts[:parent_query],
            opts[:child_query]
          )
        else
          opts[:parent_query]
        end
      end

    end
  end
end