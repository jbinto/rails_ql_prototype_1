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

      query_root = query_root_builder.data_type
      query_root.build_query!
      query_root.resolve_child_data_types!

      mutation_root = mutation_root_builder.data_type
      mutation_root.build_query!
      mutation_root.resolve_child_data_types!

      return query_root, mutation_root
    end

  end
end
