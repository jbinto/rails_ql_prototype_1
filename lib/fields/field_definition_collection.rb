class Field::FieldDefinitionCollection
  def initialize(field_definition_class)
    @field_definition_class = field_definition_class
  end

  def add_permissions(operations, opts)
    operations = [operations].flatten

    opts = {
      fields: [],
      :when => ->{true}
    }.merge opts

    operations.each do |operation|
      opts[:fields].each do |field|
        if field_definitions[field]
          field_definitions[field].send(
            :"add_#{operation}_permission",
            opts[:when]
          )
        else
          raise FieldMissing, "The field #{field} was not defined on #{self}"
        end
      end
      # if permissions.include? :write
      #   field_definitions[field].add_write_permission permission
      # end
    end
  end


  def add_field_definition(name, opts)
  end

  def add_plural_field_definition(name, opts)
  end

end
