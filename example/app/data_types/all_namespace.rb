class AllNamespace < 

  has_many(:users,
    optional_args: {admin: "BooleanValue"},
    resolve: ->(args, child_query) {
      child_query.where(args).to_a
    }
  )

  has_one(:user,
    required_args: {id: "IntValue"},
    optional_args: {email: "StringValue"},
    resolve: ->(args, child_query) {
      child_query.where(args).first!
    }
  )

  has_many(:to_dos,
    optional_args: {status: "StringValue"},
    resolve: ->(args, child_query) {
      child_query.where(args).to_a
    }
  )

  has_one(:to_do,
    required_args: {id: "IntValue"},
    resolve: ->(args, child_query) {
      child_query.where(args).first!
    }
  )

  can :read, fields: [:users, :user, :to_dos, :to_do]

end
