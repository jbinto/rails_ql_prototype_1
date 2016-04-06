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
    attr_reader :root

    def initialize(root)
      @root = root
    end

    def execute!
      root.query
      root.resolve
      # top_to_bottom_traversal
      # bottom_to_top_traversal
    end

    # protected

    # def top_to_bottom_traversal
    #   root.query
    # end

    # def bottom_to_top_traversal
    # end
  end
end