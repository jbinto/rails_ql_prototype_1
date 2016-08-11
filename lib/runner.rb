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

      ast_visitor = RailsQL::Builder::Visitor.new
      ast = GraphQL::Parser.parse query
      ast_visitor.accept ast

      # the ast_visitor returns one root builder per operation in the query document
      if ast_visitor.operations.length > 1
        raise "Can not execute multiple operations in one query document"
      end
      operation = ast_visitor.operations.first
      root_node = operation.root_node
      root_node.ctx = ctx

      # TODO: parse variables create builders and inject them into the operation
      # variable_definition_builders
      variable_value_builders = []

      # Normalize directives, variables and fragments into type builders
      builder_visitor = Builder::Normalizers::BuilderTreeVisitor.new(
        normalizers: [
          Builder::Reducers::CircularReferenceChecker.new,
          Builder::Reducers::DirectiveNormalizer.new,
          Builder::Reducers::FragmentNormalizer.new,
          Builder::Reducers::VariableNormalizer.new(
            variable_definition_builders: operation.variable_definition_builders
          )
          RailsQL::Reducers::TypeFactory.new
        ]
      )
      root_builder = builder_visitor.tree_like_fold(
        type_klass: @root_types[operation.operation_type],
        builder: root_builder,
        reducers: normalizers
      )
      # Build types
      root = RailsQL::Builder::TypeFactory.build!(
        type_klass: @root_types[operation.operation_type],
        builder: root_builder,
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
