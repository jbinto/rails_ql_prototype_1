class UserDataType < RailsQL::DataType::Base
  initial_query ->{User.all}

  has_many(:to_dos,
    args: [:status],
    query: ->(args, child_query) {query.eager_load(:to_dos).merge(child_query.where(args))},
    resolve: ->(args, child_query) {model.to_dos.first if model}
  )



  field :id, data_type: :Integer
  field :email, data_type: :String, resolve: ->(args, child_query) {model.email if model }
  field :admin, data_type: :Boolean

  can :read, fields: [:id, :to_dos, :email, :admin]

end