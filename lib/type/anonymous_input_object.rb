module RailsQL
  class Type
    class AnonymousInputObject < Type
      kind :input_object
      anonymous true
      def self.type_name
        "AnonymousInputObject"
      end
    end
  end
end
