module RailsQL
  module Field
    class FieldCollection < HashWithIndifferentAccess

      def unauthorized_fields_and_args_for(action)
        reduce(HashWithIndifferentAccess.new) do |h, (k, field)|
          if field.can? action
            json = {}
            unauthorized_fields = field
              .child_field_collection
              .unauthorized_fields_and_args_for action
            unauthorized_args = field
              .args_type
              .child_field_collection
              .unauthorized_fields_and_args_for action

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
