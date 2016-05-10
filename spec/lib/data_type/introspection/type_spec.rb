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
    runner = RailsQL::Runner.new described_class
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
      field_definition = described_class.field_definitions[:fields]

      results = field_definition.resolve(
        parent_data_type: described_class.new
      )

      expect(results.length).to eq 2
      expect(results.map &:name).to eq [
        :pandas_are_awesome,
        :because_reasons
      ]
    end
  end

end
