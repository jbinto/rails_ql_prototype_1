require "spec_helper"

describe "Acceptance tests" do
  it "all scalars on root" do
    class ScalarExample < RailsQL::Type
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
end
