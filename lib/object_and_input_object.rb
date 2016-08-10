module RailsQL
  def self.object_and_input_object(&block)
    container = Module.new
    container.const_set :ObjectType, Class.new(RailsQL::Type) do
      kind :object
    end
    container.const_set :InputObjectType, Class.new(RailsQL::Type) do
      kind :input_object
    end
    instance_eval container::ObjectType, &block
    instance_eval container::InputObjectType, &block
    return container
  end
end
