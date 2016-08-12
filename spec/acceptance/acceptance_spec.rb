require "spec_helper"

describe "Acceptance tests" do
  it "all scalars on root" do
    # To use RailsQL, you must define a **root type**.
    #
    # This type defines what fields are available at the top level of your
    # GraphQL schema.
    #
    # Types inherit from `RailsQL::Type`.

    class ScalarExample < RailsQL::Type

      # Every type must define one or more **fields**.
      #
      # Fields can point to scalar types, or object types.
      #
      # Scalar types represent concrete values such as strings and integers.
      # Object types represent nested fields in your GraphQL schema.
      #
      # The current class `ScalarExample` is an object type. It has many fields,
      # which all point to scalar types.
      #
      # When declaring a field you must provide a :type. You may use strings,
      # symbols, or class references. They can point to other RailsQL::Type
      # classes, or any built-in scalar types (:String, :Int, :Float, :Boolean
      # and :ID).
      #
      # Scalar fields must define a `resolve` lambda. This lambda has a signature
      # (args, child_query), but neither of those arguments are used in this
      # example. The return value of this lambda will be the value for this
      # field.

      field :message,
        type: :String,
        resolve: ->(args, child_query){ "Hello world!" }

      field :number,
        type: :Int,
        resolve: ->(args, child_query){ 42 }

      field :decimal,
        type: :Float,
        resolve: ->(args, child_query){ 3.14 }

      field :yes,
        type: :Boolean,
        resolve: ->(args, child_query){ true }

      field :id,
        type: :ID,
        resolve: ->(args, child_query){ "b924db28" }
    end

    runner = RailsQL::Runner.new(
      query_root: ScalarExample,
      mutation_root: nil
    )
    query_root = runner.execute!(query:
      "{ message, number, decimal, yes, id }"
    )

    expect(query_root.as_json).to eq({
      "message" => "Hello world!",
      "number" => 42,
      "decimal" => 3.14,
      "yes" => true,
      "id" => "b924db28"
    })
  end


  # You can nest types arbitrarily so long as the leaf of the tree is a scalar.
  # This example, while contrived, shows that only the `resolve` lambdas of the
  # scalar type at the bottom of the tree gets returned in the result.
  it "nested types" do
    class C < RailsQL::Type
      field :d, type: :String, resolve: ->(args, child_query){ "message" }
    end

    class B < RailsQL::Type
      field :c, type: C, resolve: ->(args, child_query){ "field_c" }
    end

    class A < RailsQL::Type
      field :b, type: B, resolve: ->(args, child_query){ "field_b" }
    end

    class NestedExample < RailsQL::Type
      field :a, type: A, resolve: ->(args, child_query){ "field_a" }
    end


    runner = RailsQL::Runner.new(
      query_root: NestedExample,
      mutation_root: nil
    )
    query_root = runner.execute!(query:
      "{ a { b { c { d }}}}"
    )

    expect(query_root.as_json).to eq(
      "a" => {
        "b" => {
          "c" => {
            "d" => "message"
          }
        }
      }
    )
  end
end


## FAQ:
##
## What is the difference between a field and a type?
##
## An object type has many fields. Those fields point to other object or scalar
## types. The tree ends when you hit a scalar (leaf). Put another way: scalar
## types are values, fields are pointers to object/scalars, and object types
## are collections of fields.
##
## What is `model` in the resolve lambda?
