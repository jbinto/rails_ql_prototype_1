module RailsQL
  module DataType
    class InputObject
      class << self
        attr_writer :anonymous

        def kind
          :INPUT_OBJECT
        end

        def anonymous
          @anonymous || false
        end

        def input_field_definitions
          @input_field_definitions ||= HashWithIndifferentAccess.new
        end

        def input_field(name, opts={})
          input_field_definitions[name.to_sym] = InputFieldDefinition.new(
            name.to_sym, opts
          )
        end

        def arg_names
          input_field_definitions.symbolize_keys.keys
        end

        def required_args
          input_field_definitions.select {|n, d| !d.optional}
        end

        def validate_input_args!(input_args)
          input_args = input_args.symbolize_keys

          unless (forbidden_args = input_args.keys - arg_names).empty?
            raise ForbiddenArg, "Invalid args: #{forbidden_args}"
          end

          required_keys = required_args.symbolize_keys.keys
          unless (missing_args = required_keys - input_args.keys).empty?
            raise(
              ArgMissing,
              "Missing required args: #{missing_args}"
            )
          end

          input_args.each do |k, v|
            unless input_field_definitions[k].arg_value_matches_type? v
              raise(
                ArgTypeError,
                "#{k} => #{v} (#{v.class}) is not a valid input value"
              )
            end
          end
        end
      end
    end
  end
end

# class AddressType < InputObject
#   description "default description"
#
#   input_field :street, type: "String", description: "blah"
#   input_field :house_number, type: "Int", description: "blah", default_value: 1
# end
#
#
# has_one(:venue, args: -> (args) {
#   args == class.new InputObject
#   args.anonymous = true
#   # ----
#   args.input_field :id, type: "Int", optional: false, description: "blah"
#   args.input_field :address, type: "AdressType", optional: false, description: "blah"
# })
