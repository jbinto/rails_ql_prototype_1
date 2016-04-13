require 'active_support/concern'

#
module RailsQL
  module DataType
    module Can
      extend ActiveSupport::Concern

      included do
        after_resolve :authorize_query!, if: :root?
      end

      def unauthorized_query_fields
        fields.reduce(HashWithIndifferentAccess.new) do |h, (k, field)|
          h[k] = true unless field.has_read_permission?
          h[k] ||= field.data_type.unauthorized_query_fields
          h
        end
      end

      def authorize_query!
        unless unauthorized_query_fields.empty?
          raise UnauthorizedQuery, unauthorized_query_fields
        end
      end

      module ClassMethods
        def can(operations, opts)
          operations = [operations].flatten

          opts = {
            fields: [],
            :when => ->{true}
          }.merge opts

          opts[:fields].each do |field|
            if operations.include? :read
              field_definitions[field].add_read_permission opts[:when]
            end
            # if permissions.include? :write
            #   field_definitions[field].add_write_permission permission
            # end
          end
        end

      end

    end
  end
end
