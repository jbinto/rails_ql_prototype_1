module RailsQL
  class Executers
    class ResolveExecuter < Executer

      def execute!
        child_resolve_nodes_for(@root).each {|node| recurse_into_child! node}
        return self
      end

      private

      def recurse_into_child!(parent:, child:)
        # Iterate top down - from the root type to the scalar leaves of the
        # type tree
        unless parent.is_a? RailsQL::Type::List
          child.model =
            if child.resolve_lambda.present?
              # todo: Directives could make use of around_resolve hooks to
              # stop resolution if there were hooks here.
              # eg. parent.trigger :around_resolve do ... end
              parent.instance_exec(
                child.args,
                child.query,
                &child.resolve_lambda
              )
            else
              default_resolve_for! parent: parent, child: child
            end
          end
        # add the children to the stack after the parent has been resolved
        child_resolve_nodes_for(child).each {|node| recurse_into_child! node}
      end

      def default_resolve_for!(parent:, child:)
        name = child.field_or_arg_name
        if parent.is_a? RailsQL::Type::NonNullable
          parent.model
        elsif parent.respond_to? name
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
