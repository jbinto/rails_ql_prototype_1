module RailsQL
  class FieldMissing < Exception
    # raised when referencing a FieldDefinition which does not exist (eg: Can)
  end
end