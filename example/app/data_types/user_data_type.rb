class UserDataType < RailsQL::DataType::Base
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

  field :id, data_type: :Integer
  field :email, data_type: :String
  field :admin, data_type: :Boolean

  can :read, fields: [:id, :to_dos, :email, :admin]

end
