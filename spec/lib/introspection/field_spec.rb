require "spec_helper"

describe RailsQL::Introspection::Field do

  before(:each) do
    allow_any_instance_of(described_class).to(
      receive(:model).and_return field_definition
    )
  end

  let(:type) do
    type_klass = class_double RailsQL::Type
    allow(type_klass).to receive(:type?).and_return true
    allow(type_klass).to receive(:type_definition).and_return(
      OpenStruct.new(
        name: "MooCow",
        kind: :OBJECT,
        enum_values: {},
        description: "https://youtu.be/u155ncSlkCk"
      )
    )

    type_klass
  end

  let(:field_definition) do
    RailsQL::Field::FieldDefinition.new("mooCows",
      type: type,
      description: "cows are awesome",
      # TODO: this is obsolete
      # required_args: {how_many_cows: {type: :Int}},
      # optional_args: {allow_future_cows: {type: :Boolean}},
      nullable: true,
      deprecated: false,
    )
  end

  let(:runner) {
    RailsQL::Runner.new(
      query_root: described_class,
      mutation_root: nil
    )
  }

  describe "[:name]" do
    it "returns the data type's name" do
      results = runner.execute!(query: "query {name}").as_json

      expect(results["name"]).to eq "mooCows"
    end
  end

  describe "[:description]" do
    it "returns the data type's description" do
      results = runner.execute!(query: "query {description}").as_json

      expect(results["description"]).to eq "cows are awesome"
    end
  end

  describe "[:args]" do
    it "returns an array of args" do
      fail "TODO: move to new args implementation"

      results = runner.execute!(query: "query {args {name}}").as_json
      expect(results["args"].map{|h| h["name"]}).to eq [
        :allow_future_cows,
        :how_many_cows
      ]
    end
  end

  describe "[:type]" do
    it "returns the data type" do
      results = runner.execute!(query: "query {type {name}}").as_json

      expect(results["type"]["name"]).to eq "MooCow"
    end
  end

  describe "[:isDeprecated]" do
    it "returns false by default" do
      results = runner.execute!(query: "query {isDeprecated}").as_json

      expect(results["isDeprecated"]).to eq false
    end

    it "returns true if the field is deprecated" do
      field_definition.deprecated = true

      results = runner.execute!(query: "query {isDeprecated}").as_json

      expect(results["isDeprecated"]).to eq true
    end
  end

  describe "[:deprecationReason]" do
    it "returns the data type" do
      reason = "Cows are been phased out in favour of Unicorns"
      field_definition.deprecation_reason = reason

      results = runner.execute!(query: "query {deprecationReason}").as_json

      expect(results["deprecationReason"]).to eq reason
    end
  end

end
