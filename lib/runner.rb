module RailsQL
  class Runner
    def initialize(query_root:, mutation_root:)
      @query_root = query_root
      @mutation_root = mutation_root
    end

    def execute!(opts)
      opts = {
        query: nil,
        ctx: {}
      }.merge opts
      if opts[:query].nil?
        raise "RailsQL::Runner.execute! requires a :query option"
      end

      query_root_builder = DataType::Builder.new(
        data_type_klass: @query_root,
        ctx: opts[:ctx],
        root: true
      )
      mutation_root_builder = DataType::Builder.new(
        data_type_klass: @mutation_root,
        ctx: opts[:ctx],
        root: true
      )

      visitor = RailsQL::Visitor.new(
        query_root_builder: query_root_builder,
        mutation_root_builder: mutation_root_builder
      )
      ast = GraphQL::Parser.parse opts[:query]
      visitor.accept ast

      # the visitor returns one root builder per operation in the query document
      if visitor.root_builders.length > 1
        raise "Can not execute multiple operations in one query document"
      end
      root = visitor.root_builders.first.data_type
      root.build_query!
      root.resolve_child_data_types!

      return root
    end

  end
end
