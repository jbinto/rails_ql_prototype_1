require "spec_helper"

describe RailsQL::Introspection::Schema do

  before(:each) do
    allow_any_instance_of(described_class).to(
      receive(:model).and_return root_type
    )
  end

  let(:user_type) do
    klass = Class.new RailsQL::Type::Type
    klass.class_eval do
      type_name "User"
      field :email, type: :String
      # Recursive association
      field :friends, type: klass
    end
    klass
  end

  let(:root_type) do
    klass = Class.new RailsQL::Type::Type
    klass.field :user, type: user_type
    klass.class_eval do
      type_name "Root"
      field :user_count, type: :Int
    end
    klass
  end

  let(:runner) {
    RailsQL::Runner.new described_class
  }

  describe "[:types]" do
    it "returns an array of [__Type]" do
      results = runner.execute!(query: "query {types {name}}").as_json

      expect(results["types"].map{|h| h["name"]}.sort).to eq [
        "Root",
        "User",
        "String",
        "Int"
      ].sort
    end
  end

  describe "[:queryType]" do
    it "returns the root __Type" do
      results = runner.execute!(query: "query {queryType {name}}").as_json

      expect(results["queryType"]["name"]).to eq "Root"
    end
  end

  describe "[:mutationType]" do
    # TODO: implement mutations
    it "returns nil" do
      results = runner.execute!(query: "query {mutationType {name}}").as_json

      expect(results["mutationType"]).to eq nil
    end
  end

  describe "[:directives]" do
    # TODO: implement mutations
    it "returns an empty array" do
      results = runner.execute!(query: "query {directives {name}}").as_json

      expect(results["directives"]).to eq []
    end
  end

end
