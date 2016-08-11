class ToDoType < RailsQL::Type
  initial_query ->{ToDo.all}

  has_one(:user,
    query: ->(args, child_query) {
      query.eager_load(:users).merge(child_query.where(args))
    },
    resolve: ->(args, child_query) {model.user}
  )

  field :id, type: :Integer
  field :status, type: :String
  field :content, type: :String

  can :query, fields: [:id, :user, :status, :content]

end
