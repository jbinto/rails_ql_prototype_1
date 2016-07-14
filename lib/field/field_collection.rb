module RailsQL
  module Field
    class FieldCollection
      attr_accessor :fields

      def unauthorized_fields_for(action)
        fields.reduce(HashWithIndifferentAccess.new) do |h, (k, field)|
          json = field.can?(action) ? nil : true
          json ||= {}.merge(*field.child_field_collections.map{|collection|
            collection.unauthorized_fields_for action
          })
          h[k] = json if json.present?
          h
        end
      end
    end
  end
end
