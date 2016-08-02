module RailsQL
  class Type
    class AnonymousInputObject < RailsQL::Type
      kind :input_object
      anonymous true
    end
  end
end
