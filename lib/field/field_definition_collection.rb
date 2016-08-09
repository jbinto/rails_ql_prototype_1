require_relative "./field_definition.rb"

module RailsQL
  module Field
    class FieldDefinitionCollection < HashWithIndifferentAccess
      # TODO: switch to hash inheritance
      # attr_reader :field_definitions

      # def initialize
      #   @field_definitions = HashWithIndifferentAccess.new
      # end

      # note: Permissions will only be applied to the fields provided in `opts[:fields]`
      def add_permissions(operations, opts)
        operations = [operations].flatten

        opts = {
          fields: [],
          :when => ->{true}
        }.merge opts

        operations.each do |operation|
          opts[:fields].each do |field|
            if self[field]
              self[field].add_permission!(
                operation,
                opts[:when]
              )
            else
              msg = "The field #{field} was not defined"
              raise FieldMissing, msg
            end
          end
          # if permissions.include? :write
          #   field_definitions[field].add_write_permission permission
          # end
        end
      end

      def add_field_definition(name, opts)
        instance_methods = Type.instance_methods

        name = name.to_s
        if name.starts_with?("__") && !opts[:introspection]
          raise(
            RailsQL::InvalidField,
            "#{name} is an invalid field; names must not be " +
            "prefixed with double underscores"
          )
        end

        if (instance_methods).include?(name.to_sym) && opts[:resolve].nil?
          raise(
            RailsQL::InvalidField,
            "Reserved word: Can not use #{name} as a field name without a " +
            ":resolve option"
          )
        end

        self[name] = RailsQL::Field::FieldDefinition.new name, opts
      end

      def add_plural_field_definition(name, opts)
        add_field_definition name, opts.merge(singular: false)
      end

    end
  end
end
