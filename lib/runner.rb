  # class Runner
  #   def initialize(schema_klass)
  #     @schema_klass = schema_klass
  #   end

  #   def parse!(graphql)
  #     visitor = RailsQLVisitor.new(@schema_klass.new(parent: nil))
  #     ast = GraphQL::Parser.parse(graphql)
  #     visitor.accept(ast)
  #     # idea: multi-thread for multiple roots
  #     runner = RailsQL::Runner.new(visitor.root)
  #     runner.execute!
  #   end
  # end

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
      if query.nil? raise "RailsQL::Runner.execute! requires a :query option"

      root_builder = Builder.new(
        data_type_klass: @schema,
        ctx: ctx,
        root: true
      )

      visitor = RailsQL::Visitor.new root_builder
      ast = GraphQL::Parser.parse opts[:query]
      visitor.accept ast

      root = root_builder.data_type
      root.build_query!
      root.resolve_child_data_types!

      return root
    end

  end
end
