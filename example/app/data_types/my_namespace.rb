class MyNamespace < RailsQL::DataType::Base

  has_one(:user,
    resolve: ->(args, child_query) {
      child_query.where(id: ctx[:current_user].id).first
    }
  )

  has_many(:to_dos,
    optional_args: {status: "StringValue"},
    resolve: ->(args, child_query) {
      child_query.where(args.merge user_id: ctx[:current_user].id).to_a
    }
  )

  has_one(:to_do,
    required_args: {id: "IntValue"},
    resolve: ->(args, child_query) {
      child_query.where(args.merge user_id: ctx[:current_user].id).first
    }
  )

  can :read, fields: [:user, :to_dos, :to_do]

end
