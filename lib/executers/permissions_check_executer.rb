module RailsQL
  class Executers
    class PermissionsCheckExecuter < Executer
      attr_reader :unauthorized_fields_and_args

      def execute!
        @unauthorized_fields_and_args ||= unauthorized_fields_and_args_for(
          @operation_type,
          parent: @root
        )
        return self
      end

      private
      def unauthorized_fields_and_args_for(action, parent:)
        result = parent.query_tree_children.reduce({}) do |h, child|
          if parent.can? action, child.field_or_arg_name
            json = {}
            unauthorized_fields = unauthorized_fields_and_args_for(
              action,
              parent: child
            )
            unauthorized_args = unauthorized_fields_and_args_for(
              :input,
              parent: child.args_type
            )

            json.merge! *unauthorized_fields if unauthorized_fields.present?
            json["__args"] = unauthorized_args if unauthorized_args.present?
          else
            json = true
          end

          h[child.aliased_as] = json if json.present?
          h
        end

        result
      end

    end
  end
end
