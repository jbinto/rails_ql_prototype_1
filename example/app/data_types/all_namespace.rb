class AllNamespace < RailsQL::DataType::Base

  has_many(:users,
    arg_whitlist: [:admin],
    resolve: ->(args, child_query) {
      child_query.where(args).to_a
    }
  )

  has_many(:user,
    arg_whitlist: [:id, :email],
    resolve: ->(args, child_query) {
      child_query.where(args).first!
    }
  )

  has_many(:to_dos,
    arg_whitlist: [:status],
    resolve: ->(args, child_query) {
      child_query.where(args).to_a
    }
  )

  has_one(:to_do,
    arg_whitlist: [:id],
    resolve: ->(args, child_query) {
      child_query.where(args).first!
    }
  )

  can :read, fields: [:users, :user, :to_dos, :to_do]

end
