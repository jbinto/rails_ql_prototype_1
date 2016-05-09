require "spec_helper"

describe RailsQL::DataType::Introspection::Type do

  let(:data_type_klass) do
    klass = Class.new RailsQL::DataType::Base
    klass.class_eval do
      def self.name
        "Panda"
      end
      description "https://youtu.be/u155ncSlkCk"
      # field :pandas_are_awesome, data_type: :Boolean
    end
    klass
  end

  describe "recurse_over_data_type_klasses" do
    it "returns an array with the name and description of every data_type" do
      allow_any_instance_of(described_class).to(
        receive(:model).and_return data_type_klass
      )
      runner = RailsQL::Runner.new described_class

      results = runner.execute!(query: "query {name, description}").as_json

      expect(results["name"]).to eq "Panda"
      expect(results["description"]).to eq "https://youtu.be/u155ncSlkCk"
      # expect(results["fields"]).to eq [a field for "pandas_are_awesome"]
    end
  end
end
