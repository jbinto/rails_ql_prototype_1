module RailsQL
  class Runner

    def initialize(query_root:, mutation_root:)
      @root_types = {
        query: query_root,
        mutation: mutation_root
      }
    end

    def execute!(
      query:,
      ctx: {},
      variables: {}
    )

      visitor = RailsQL::Visitor.new
      ast = GraphQL::Parser.parse opts[:query]
      visitor.accept ast

      # the visitor returns one root builder per operation in the query document
      if visitor.operations.length > 1
        raise "Can not execute multiple operations in one query document"
      end
      operation = visitor.operations.first
      root_builder = operation.root_builder
      # Normalize variable and fragment builders into type builders (TODO!)
      # root = root_builder
      #   .normalize_fragments!
      #   .normalize_variables!
      # OR
      # RailQL::Builder::FragmentNormalizer.normalize!(operation)
      # RailQL::Builder::VariablesNormalizer.normalize!(operation)

      # Build types
      root = RailQL::Builder::TypeFactory.build!(
        type_klass: root_types[operation.operation_type],
        builder: root_builder,
        ctx: opts[:ctx]
      )
      # Execution:
      # 1. Permissions check
      # 2. Query
      # 3. Resolve
      executer_opts = {
        root: root,
        operation_type: operation.operation_type
      }
      # Permissions check
      permissions_executer = Executers::PermissionsCheckExecuter executer_opts
      unauth_errors = permissions_executer.unauthorized_fields_and_args
      if unauth_errors.present?
        raise RailsQL::Forbidden.new("Access Forbidden",
          errors_json: unauth_errors
        )
      end
      # Query + Resolve
      Executers::QueryExecuter.new(executer_opts).execute!
      Executers::ResolveExecuter.new(executer_opts).execute!
      return root
    end

  end
end
