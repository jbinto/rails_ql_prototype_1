class MyNamespace < RailsQL::DataType::Base

  has_one(:user,
    resolve: ->(args, child_query) {
      child_query.where(id: ctx[:current_user].id).to_a.first
    }
  )

  has_many(:to_dos,
    args: [:status],
    resolve: ->(args, child_query) {
      child_query.where(args.merge user_id: ctx[:current_user].id).to_a.first
    }
  )

  has_one(:to_do,
    args: [:id],
    resolve: ->(args, child_query) {
      child_query.where(args.merge user_id: ctx[:current_user].id).to_a.first
    }
  )

  can :read, fields: [:user, :to_dos, :to_do]

end