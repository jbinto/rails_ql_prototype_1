class ToDoDataType < RailsQL::DataType::Base
  initial_query ->{ToDo.all}

  has_one(:user,
    query: ->(args, child_query) {query.join child_query}
  )

  field :id, data_type: :Integer
  field :status, data_type: :String
  field :content, data_type: :String

  can :read, fields: [:id, :user, :status, :content]

end