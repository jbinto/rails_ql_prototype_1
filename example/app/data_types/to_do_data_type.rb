class ToDoDataType < RailsQL::Type::Type
  initial_query ->{ToDo.all}

  has_one(:user,
    query: ->(args, child_query) {
      query.eager_load(:users).merge(child_query.where(args))
    },
    resolve: ->(args, child_query) {model.user}
  )

  field :id, data_type: :Integer
  field :status, data_type: :String
  field :content, data_type: :String

  can :read, fields: [:id, :user, :status, :content]

end
