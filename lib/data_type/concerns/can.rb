require 'active_support/concern'

#
module RailsQL
  module DataType
    module Can
      extend ActiveSupport::Concern

      included do
        after_resolve :authorize_query!, if: :root?
      end

      def unauthorized_query_fields(sub_fields=nil)
        fields = sub_fields || @fields
        @unauthorized_query_fields ||= fields.reduce([]) do |unauthed_fields, (field_name, data_type)|
          if self.class.field_definitions[field_name.to_sym].readable?
            unauthed_fields << {
              field_name => unauthorized_query_fields(data_type.fields)
            }
          else
            unauthed_fields << field_name
          end
        end.compact
      end

      def authorize_query!
        unless unauthorized_query_fields.empty?
          raise UnauthorizedQuery, unauthorized_query_fields
        end

        true
      end

      module ClassMethods
        def can(permissions, opts)
          permissions = [permissions].flatten

          if permissions.include? :read
            can_read opts[:fields], opts.except(:field)
          end
          if permissions.include? :write
            can_write opts[:fields], opts.except(:field)
          end
        end

        protected

        def can_read(fields, opts)
          permission = opts[:when] || ->{true}
          fields.each do |field|
            field_definitions[field].add_read_permission permission
          end
        end

        def can_write(field, opts)
        end
      end

    end
  end
end
