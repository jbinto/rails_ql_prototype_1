class Schema < RailsQL::DataType::Base
  include RailsQL::DataType::Introspection

  has_one(:my,
    data_type: "MyNamespace",
    resolve: ->(args, child_query) {:my}
  )

  has_one(:all,
    data_type: "AllNamespace",
    resolve: ->(args, child_query) {:all}
  )

  can :read, fields: [:my]
  can :read, fields: [:all], when: -> {ctx[:current_user].admin?}

end