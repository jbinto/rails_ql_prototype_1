module RailsQL
  class NullField < Exception
    # raised when a query returns nil for a field with nullable: false
  end
end