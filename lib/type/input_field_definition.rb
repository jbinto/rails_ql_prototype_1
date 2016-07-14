module RailsQL
  class Type
    class InputFieldDefinition
      attr_accessor :name, :type, :description, :optional, :default_value

      ARG_TYPE_TO_RUBY_CLASSES = {
        Int: [Fixnum],
        Float: [Float],
        String: [String],
        Boolean: [TrueClass, FalseClass],
        Enum: [String, Fixnum],
        List: [Array]
      }

      ARG_TYPES = ARG_TYPE_TO_RUBY_CLASSES.keys

      def initialize(name, opts)
        @name = name

        defaults = {
          type: "#{name.to_s.singularize.classify}InputType",
          description: nil,
          optional: true,
          default_value: nil
        }
        opts = defaults.merge(opts.slice *defaults.keys)
        if opts[:description]
          opts[:description] = opts[:description].gsub(/\n\s+/, "\n").strip
        end
        opts.each do |key, value|
          instance_variable_set "@#{key}", value
        end

        validate_type!
      end

      def arg_value_matches_type?(value)
        if ARG_TYPES.include? type
          ARG_TYPE_TO_RUBY_CLASSES[type].include? value.class
        else
          return false unless value.kind_of? Hash

          begin
            type.to_s.constantize.validate_input_args! value
            true
          rescue RailsQL::ArgTypeError, RailsQL::ForbiddenArg
            false
          end
        end
      end

      protected

      def validate_type!
        self.type = type.to_s.to_sym

        return if ARG_TYPES.include? type
        return if type.to_s.constantize.kind == :INPUT_OBJECT
        rescue NameError

        raise(
          InvalidArgType,
          "#{type} on #{name} is not a valid arg type"
        )
      end
    end
  end
end
