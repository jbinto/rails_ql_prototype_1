class Schema < RailsQL::DataType::Base

  has_one(:my,
    data_type: "MyNamespace",
    resolve: ->(args, child_query) {nil}
  )

  has_one(:all,
    data_type: "AllNamespace",
    resolve: ->(args, child_query) {nil}
  )

  can :read, fields: [:my]
  can :read, fields: [:all], when: -> {ctx[:current_user].admin?}

end