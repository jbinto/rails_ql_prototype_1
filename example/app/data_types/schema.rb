class Schema < 
  include RailsQL::Introspection

  has_one(:my,
    type: "MyNamespace",
    resolve: ->(args, child_query) {:my}
  )

  has_one(:all,
    type: "AllNamespace",
    resolve: ->(args, child_query) {:all}
  )

  can :read, fields: [:my]
  can :read, fields: [:all], when: -> {ctx[:current_user].admin?}

end