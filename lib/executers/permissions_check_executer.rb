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
        # binding.pry
        puts "BEGIN@@ reducing parent=#{parent}"
        result = parent.query_tree_children.reduce({}) do |h, child|
          puts "  parent=#{parent}  h=#{h} child=#{child}"
          # binding.pry
          if parent.can? action, child.field_name
            puts "  parent_can? #{action} #{child.field_name} => true"
            json = {}
            puts "    BEGIN~~ recursion into nested fields of #{parent} (new_parent: child => #{child}"
            unauthorized_fields = unauthorized_fields_and_args_for(
              action,
              parent: child
            )
            puts "    END~~ recursion into nested fields of #{parent}"
            puts "    BEGIN!! recursion into args of #{parent} (new_parent: child.args_type => #{child.args_type})"
            unauthorized_args = unauthorized_fields_and_args_for(
              :input,
              parent: child.args_type
            )
            puts "    END!! recursion into args of #{parent}"

            json.merge! *unauthorized_fields if unauthorized_fields.present?
            json["__args"] = unauthorized_args if unauthorized_args.present?
          else
            puts "  parent_can? #{action} #{child.field_name} => false  "
            json = true
          end

          # XXX h[k] ??
          h[child.field_name] = json if json.present?
          h
        end
        puts "END@@ reducing parent=#{parent}"

        result
      end

    end
  end
end
