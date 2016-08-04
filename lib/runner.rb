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

      query_root_builder = Builder::TypeBuilder.new(
        type_klass: @query_root,
        ctx: opts[:ctx],
        root: true
      )
      mutation_root_builder = Builder::TypeBuilder.new(
        type_klass: @mutation_root,
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
      if visitor.operations.length > 1
        raise "Can not execute multiple operations in one query document"
      end
      operation = visitor.operations.first
      root_builder = operation.root_builder
      # Normalization
      root = root_builder
        .normalize_fragments!
        .normalize_variables!
        .build_type!
      # Execution
      executers = {}
      [
        query: RailsQL::Executers::QueryExecuter,
        resolve: RailsQL::Executers::ResolveExecuter,
        permissions_check: RailsQL::Executers::PermissionsCheckExecuter
      ].each do |k, executer|
        executers[k] = executer.new(
          root: root,
          operation_type: operation.operation_type
        ).execute!
      end
      unauth_errors = executers[:permissions_check].unauthorized_fields_and_args
      if unauth_errors.present?
        raise RailsQL::Forbidden.new("Access Forbidden",
          errors_json: unauth_errors
        )
      end
      return root
    end

  end
end
