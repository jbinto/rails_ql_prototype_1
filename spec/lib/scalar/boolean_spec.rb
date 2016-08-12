require "spec_helper"

describe RailsQL::Scalar::Boolean do
  describe "#parse_value" do
    def parse(value)
      described_class.new.parse_value!(value)
    end

    it "passes through true, false, nil" do
      expect(parse true).to eq true
      expect(parse false).to eq false
      expect(parse nil).to eq nil
    end

    it "raises on everything else" do
      expect{parse "true"}.to raise_error #ArgTypeError
      expect{parse 42}.to raise_error
      expect{parse a: 1, b: 2}.to raise_error
    end
  end
end
