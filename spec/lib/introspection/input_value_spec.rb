require "spec_helper"

describe RailsQL::Introspection::InputValue do

  before(:each) do
    allow_any_instance_of(described_class).to(
      receive(:model).and_return(
        name: "howGreatAreUnicorns",
        # TODO: These aren't implemented yet:
        # description: "I <3 Unicorns",
        # type: type
        # defaultValue: "__SO__FREAKING__AWESOME__"
      )
    )
  end

  # TODO: not implemented yet:
  # let(:type) do
  #   type = class_double RailsQL::Type::Type
  #   allow(type).to receive(:type?).and_return true
  #   allow(type).to receive(:name).and_return "UnicornAwesomeness"
  #   type
  # end

  let(:runner) {
    RailsQL::Runner.new described_class
  }

  describe "[:name]" do
    it "returns the input value's name" do
      results = runner.execute!(query: "query {name}").as_json

      expect(results["name"]).to eq "howGreatAreUnicorns"
    end
  end

  describe "[:description]" do
    it "returns the data type's description" do
      pending
      fail

      results = runner.execute!(query: "query {description}").as_json

      expect(results["description"]).to eq "I <3 Unicorns"
    end
  end

  describe "[:type]" do
    it "returns the data type" do
      pending
      fail

      results = runner.execute!(query: "query {type {name}}").as_json

      expect(results["type"]["name"]).to eq "UnicornAwesomeness"
    end
  end

  describe "[:defaultValue]" do
    it "returns the default value" do
      pending
      fail

      results = runner.execute!(query: "query {defaultValue}").as_json

      expect(results["type"]["name"]).to eq "__SO__FREAKING__AWESOME__"
    end

  end

end
