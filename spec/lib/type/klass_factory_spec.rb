require "spec_helper"

describe RailsQL::Type::KlassFactory do
  describe ".find" do
    context "when klass is a non-built-in data type" do
      it "returns the klass untouched" do
        type = class_double RailsQL::Type::Type
        allow(type).to receive(:type?).and_return true

        results = described_class.find type

        expect(results).to eq type
      end
    end

    context "when klass is a string or symbol" do
      it "returns a constantized klass" do
        results = described_class.find "RailsQL::Type"

        expect(results).to eq RailsQL::Type
      end
    end

    context "when klass is a built-in scalar type without a namespace" do
      it "returns the scalar klass" do
        results = described_class.find "String"

        expect(results).to eq RailsQL::Scalar::String
      end
    end
  end
end
