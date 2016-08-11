class UserType < RailsQL::Type
  initial_query ->{User.all}

  has_many(:to_dos,
    optional_args: {status: "StringValue"},
    query: ->(args, child_query) {
      association = status_arg_to_association_name args[:status]
      query.eager_load association
    },
    resolve: ->(args, child_query) {
      association = status_arg_to_association_name args[:status]
      model.send(association).to_a
    }
  )

  def status_arg_to_association_name(status)
    if status == "complete"
      :complete_to_dos
    elsif status == "incomplete"
      :incomplete_to_dos
    else
      :to_dos
    end
  end

  field :id, type: :Integer
  field :email, type: :String
  field :admin, type: :Boolean

  can :query, fields: [:id, :to_dos, :email, :admin]

end
