module RailsQL
  class Executers
    class ResolveExecuter < Executer

      def execute!
        stack = child_resolve_nodes_for @root

        # Iterate from the root type to the scalar leaves of the type tree
        stack.each do |node|
          [child, parent] = node.slice :child, :parent

          stack << child_resolve_nodes_for child
          child.model =
            if child.resolve_lambda.present?
              # todo: Directives could make use of around_resolve hooks to
              # stop resolution if there were hooks here.
              # eg. parent.trigger :around_resolve do ... end
              parent.instance_exec(
                child.args,
                parent.query,
                child.resolve_lambda
              )
            else
              default_resolve_for! node
            end
        end
        return self
      end

      private

      def default_resolve_for!(child:, parent:)
        name = child.name
        if parent.respond_to? name
          parent.send name
        elsif parent.model.respond_to? name
          parent.model.send name
        else
          raise(
            RailsQL::NullResolve,
            "#{parent.class}##{name} does not have an explicit " +
            "resolve, nor does the model respond to :#{name}."
          )
        end
      end

    end
  end
end
