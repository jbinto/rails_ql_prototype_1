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
          json = parent.can?(action, child.name) ? nil : true
          json ||= {}.merge(
            *child.fields.map{|collection|
              collection.unauthorized_fields_for action
            }
          )
          args_collection = field.args.field_collection
          unauthorized_args = args_collection.unauthorized_fields_for action

          if json.is_a?(Hash) && unauthorized_args.present?
            json["__args"] = unauthorized_args
          end
          h[k] = json if json.present?
          h
        end
      end

    end
  end
end
