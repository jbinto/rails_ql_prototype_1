require "spec_helper"

describe RailsQL::Introspection::Type do

  before(:each) do
    allow_any_instance_of(described_class).to(
      receive(:model).and_return type_klass
    )
  end

  let(:field_definitions) do
    definitions = {
      pandas_are_awesome: instance_double(RailsQL::Field::FieldDefinition),
      because_reasons: instance_double(RailsQL::Field::FieldDefinition)
    }
    definitions.each do |name, definition|
      allow(definition).to receive(:name).and_return name
      allow(definition).to receive(:deprecated?).and_return false
    end
    definitions
  end

  let(:type_klass) do
    klass = class_double RailsQL::Type::Type
    allow(klass).to receive(:type_definition).and_return OpenStruct.new(
      name: "Panda",
      kind: :OBJECT,
      enum_values: {
        mega_panda: OpenStruct.new(name: "mega_panda"),
        normal_panda: OpenStruct.new(name: "normal_panda")
      },
      description: "https://youtu.be/u155ncSlkCk"
    )
    allow(klass).to receive(:field_definitions).and_return field_definitions
    klass
  end

  let(:runner) {
    RailsQL::Runner.new described_class
  }

  describe "[:kind]" do
    it "returns the data type's name" do
      results = runner.execute!(query: "query {kind}").as_json

      expect(results["kind"]).to eq "OBJECT"
    end
  end

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

  describe "[:enumValues]" do
    it "resolves to an array of the enum values" do
      results = runner.execute!(query: "query {enumValues {name}}").as_json

      expect(results["enumValues"]).to eq [
        {"name" => "mega_panda"},
        {"name" => "normal_panda"}
      ]
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
