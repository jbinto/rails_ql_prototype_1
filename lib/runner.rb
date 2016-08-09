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

      visitor = RailsQL::Builder::Visitor.new
      ast = GraphQL::Parser.parse query
      visitor.accept ast

      # TODO: parse variables and create builders
      variable_builders = []

      # the visitor returns one root builder per operation in the query document
      if visitor.operations.length > 1
        raise "Can not execute multiple operations in one query document"
      end
      operation = visitor.operations.first
      root_builder = operation.root_builder
      # Normalize directives and fragments into type builders
      Builder::Normalizer.normalize!(
        type_klass: @root_types[operation.operation_type],
        builder: root_builder
      )
      # Build types
      root = RailsQL::Builder::TypeFactory.build!(
        type_klass: @root_types[operation.operation_type],
        builder: root_builder,
        ctx: ctx,
        variable_builders: variable_builders
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
      permissions_executer = Executers::PermissionsCheckExecuter.new(
        executer_opts
      )
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
