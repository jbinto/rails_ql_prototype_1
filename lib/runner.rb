module RailsQL
  class Runner
    def initialize(schema)
      @schema = schema
    end

    def execute!(opts)
      opts = {
        query: nil,
        ctx: {}
      }.merge opts
      if opts[:query].nil?
        raise "RailsQL::Runner.execute! requires a :query option"
      end

      root_builder = DataType::Builder.new(
        data_type_klass: @schema,
        ctx: opts[:ctx],
        root: true
      )

      visitor = RailsQL::Visitor.new root_builder
      p "query"
      p opts[:query]
      ast = GraphQL::Parser.parse opts[:query]
      visitor.accept ast

      root = root_builder.data_type
      root.build_query!
      root.resolve_child_data_types!

      return root
    end

  end
end
