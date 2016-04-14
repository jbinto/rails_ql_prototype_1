class AllNamespace < RailsQL::DataType::Base

  has_many(:users,
    args: [:admin],
    resolve: ->(args, child_query) {
      child_query.where(args)
    }
  )

  has_many(:user,
    args: [:id, :email],
    resolve: ->(args, child_query) {
      child_query.where(args).first!
    }
  )

  has_many(:to_dos,
    args: [:status],
    resolve: ->(args, child_query) {
      child_query.where(args).to_a.first
    }
  )

  has_one(:to_do,
    args: [:id],
    resolve: ->(args, child_query) {
      child_query.where(args).first!
    }
  )

  can :read, fields: [:users, :user, :to_dos, :to_do]

end