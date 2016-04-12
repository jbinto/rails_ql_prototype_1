require "spec_helper"

describe RailsQL::DataType::KlassFactory do
  describe ".find" do
    context "when klass is a constant" do
      it "returns the klass untouched" do
        klass = described_class.find RailsQL::DataType::Base

        expect(klass).to eq RailsQL::DataType::Base
      end
    end

    context "when klass is a string or symbol" do
      it "returns a constantized klass" do
        klass = described_class.find "RailsQL::DataType::Base"

        expect(klass).to eq RailsQL::DataType::Base
      end
    end

    context "when klass is a primative type without a namespace" do
      it "returnsa primative klass with a namespace" do
        klass = described_class.find "String"

        expect(klass).to eq RailsQL::DataType::Primative::String
      end
    end
  end
end