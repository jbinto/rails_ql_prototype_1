module RailsQL
  class Executers
    class PermissionsCheckExecuter < Executer
      attr_reader :unauthorized_fields_and_args

      def execute!
        @unauthorized_fields_and_args =
          unauthorized_fields_and_args_for(@operation, parent: @root)
        # stack = child_nodes_for @root
        #
        # # Iterate from the root type to the scalar leaves of the type tree
        # stack.each do |node|
        #   [child, parent] = node.slice :child, :parent
        #
        #   parent.can? action, child.name
        #
        # end
      end

      private
      def unauthorized_fields_and_args_for(action, parent:)
        parent.fields.reduce(HashWithIndifferentAccess.new) do |h, (k, child)|
          if parent.can? action, child.name
            json = {}
            unauthorized_fields = unauthorized_fields_and_args_for(
              action
              parent: child
            )
            unauthorized_args = unauthorized_fields_and_args_for(
              :input,
              parent: child_type.args_type
            )

            json.merge! *unauthorized_fields if unauthorized_fields.present?
            json["__args"] = unauthorized_args if unauthorized_args.present?
          else
            json = true
          end

          h[k] = json if json.present?
          h
        end
      end

    end
  end
end
