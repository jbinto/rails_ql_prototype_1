module RailsQL
  class NullResolve < Exception
    # raised when a field definition does not have an explicit resolve, nor does
    # the model/type respond to the field name as a method
  end
end
