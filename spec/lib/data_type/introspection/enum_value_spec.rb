require "spec_helper"

describe RailsQL::DataType::Introspection::EnumValue do

  before(:each) do
    allow_any_instance_of(described_class).to(
      receive(:model).and_return enum_type
    )
  end

  let(:enum_type) do
    # TODO: enum types
    OpenStruct.new(
      name: "Panda",
      description: "https://youtu.be/u155ncSlkCk",
      is_deprecated: true,
      deprecation_reason: "not enough pandas"
    )
  end

  let(:runner) {
    RailsQL::Runner.new described_class
  }

  describe "[:name]" do
    it "returns the enum value's name" do
      results = runner.execute!(query: "query {name}").as_json

      expect(results["name"]).to eq "Panda"
    end
  end

  describe "[:description]" do
    it "returns the enum value's description" do
      results = runner.execute!(query: "query {description}").as_json

      expect(results["description"]).to eq "https://youtu.be/u155ncSlkCk"
    end
  end

  # TODO: interfaces
  describe "[:isDeprecated]" do
    it "resolves to a boolean" do
      results = runner.execute!(query: "query {isDeprecated}").as_json

      expect(results["isDeprecated"]).to eq true
    end
  end

  # TODO: possibleTypes
  describe "[:deprecationReason]" do
    it "resolves to the reason" do
      results = runner.execute!(query: "query {deprecationReason}").as_json

      expect(results["deprecationReason"]).to eq "not enough pandas"
    end
  end

end
