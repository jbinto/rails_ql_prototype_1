module RailsQL
  module Field
    class FieldCollection < HashWithIndifferentAccess

      def unauthorized_fields_and_args_for(action)
        reduce(HashWithIndifferentAccess.new) do |h, (k, field)|
          json = field.can?(action) ? nil : true
          json ||= {}.merge(
            *field.child_field_collections.map{|collection|
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
