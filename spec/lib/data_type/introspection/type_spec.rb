require "spec_helper"

describe RailsQL::DataType::Introspection::Type do

  before(:each) do
    allow_any_instance_of(described_class).to(
      receive(:model).and_return data_type_klass
    )
  end

  let(:data_type_klass) do
    klass = Class.new RailsQL::DataType::Base
    klass.class_eval do
      def self.name
        "Panda"
      end
      description "https://youtu.be/u155ncSlkCk"
      field :pandas_are_awesome, data_type: :Boolean
      field :because_reasons, data_type: :Boolean
    end
    klass
  end

  let(:runner) {
    RailsQL::Runner.new described_class
  }

  describe "[:name]" do
    it "returns the data type's name" do
      results = runner.execute!(query: "query {name}").as_json

      expect(results["name"]).to eq "Panda"
    end
  end

  describe "[:description]" do
    it "returns the data type's description" do
      results = runner.execute!(query: "query {description}").as_json

      expect(results["description"]).to eq "https://youtu.be/u155ncSlkCk"
    end
  end

  describe "[:fields]" do
    it "resolves to a list of field definitions" do
      results = runner.execute!(query: "query {fields {name}}").as_json

      expect(results["fields"].length).to eq 2
      expect(results["fields"].map {|h| h["name"]}).to eq [
        :pandas_are_awesome,
        :because_reasons
      ]
    end
  end

  # TODO: interfaces
  describe "[:interfaces]" do
    it "resolves to an empty array" do
      results = runner.execute!(query: "query {interfaces {name}}").as_json

      expect(results["interfaces"]).to eq []
    end
  end

  # TODO: possibleTypes
  describe "[:possibleTypes]" do
    it "resolves to an empty array" do
      results = runner.execute!(query: "query {possibleTypes {name}}").as_json

      expect(results["possibleTypes"]).to eq []
    end
  end

  # TODO: enumValues
  describe "[:enumValues]" do
    it "resolves to an empty array" do
      results = runner.execute!(query: "query {enumValues {name}}").as_json

      expect(results["enumValues"]).to eq []
    end
  end

  # TODO: inputFields
  describe "[:inputFields]" do
    it "resolves to an empty array" do
      results = runner.execute!(query: "query {inputFields {name}}").as_json

      expect(results["inputFields"]).to eq []
    end
  end

  # TODO:
  describe "[:ofType]" do
    it "resolves to nil" do
      results = runner.execute!(query: "query {ofType {name}}").as_json

      expect(results["ofType"]).to eq nil
    end
  end

end
