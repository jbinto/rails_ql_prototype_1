require "spec_helper"

describe RailsQL::Type::InputFieldDefinition do
  describe "#validate_type!" do
    context "when type belongs to .ARG_TYPES" do
      it "does not raise an error" do
        expect{described_class.new(:id,
          type: "Int", description: "The identifier value"
        )}.to_not raise_error
      end
    end

    context "when type does not belong to .ARG_TYPES" do
      context "when type is defined" do
        it "does not raise an error" do
          CustomType = Class.new RailsQL::Type::InputObject
          expect{described_class.new(:id,
            type: "CustomType", description: "User defined arg type"
          )}.to_not raise_error
        end
      end

      context "when type is not defined" do
        it "raises an error" do
          expect{described_class.new(:id,
            type: "FakeType", description: "undefined type"
          )}.to raise_error
        end
      end
    end
  end

  describe "arg_value_matches_type?" do
    it "returns whether or not the arg value class is included in the defined types" do
      AddressType = Class.new RailsQL::Type::InputObject
      AddressType.input_field :street, type: "String"
      id_definition = described_class.new :id, type: "Int"
      name_definition = described_class.new :name, type: "String"
      complete_definition = described_class.new :complete, type: "Boolean"
      address_definition = described_class.new :address, type: "AddressType"

      expect(id_definition.arg_value_matches_type?(3)).to eq true
      expect(id_definition.arg_value_matches_type?('3')).to eq false
      expect(id_definition.arg_value_matches_type?(true)).to eq false

      expect(name_definition.arg_value_matches_type?('steve')).to eq true
      expect(name_definition.arg_value_matches_type?(3)).to eq false

      expect(complete_definition.arg_value_matches_type?(true)).to eq true
      expect(complete_definition.arg_value_matches_type?(false)).to eq true
      expect(complete_definition.arg_value_matches_type?(3)).to eq false

      expect(address_definition.arg_value_matches_type?(street: "Fake St")).to eq(
        true
      )
      expect(address_definition.arg_value_matches_type?(street: 3)).to eq(
        false
      )
      expect(address_definition.arg_value_matches_type?(random_key: "Moo")).to(
        eq false
      )
      expect(address_definition.arg_value_matches_type?(3)).to eq false
    end
  end
end
