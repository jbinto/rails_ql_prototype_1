require "spec_helper"

describe RailsQL::Type::KlassFactory do
  describe ".find" do
    context "when klass is a non-primative data type" do
      it "returns the klass untouched" do
        data_type = class_double RailsQL::Type::Type
        allow(data_type).to receive(:data_type?).and_return true

        results = described_class.find data_type

        expect(results).to eq data_type
      end
    end

    context "when klass is a string or symbol" do
      it "returns a constantized klass" do
        results = described_class.find "RailsQL::Type::Type"

        expect(results).to eq RailsQL::Type::Type
      end
    end

    context "when klass is a primative type without a namespace" do
      it "returnsa primative klass with a namespace" do
        results = described_class.find "String"

        expect(results).to eq RailsQL::Type::Primative::String
      end
    end
  end
end
