require "spec_helper"

describe RailsQL::DataType::InputObject do
  describe "#validate_arg_types!" do
    context "when args have types belonging to .ARG_TYPES" do
      it "does not raise an error" do
        described_class.input_field(:id,
          type: "Int", description: "The identifier value"
        )
        expect{described_class.validate_arg_types!}.to_not raise_error
      end
    end

    context "when optional or required args have types not belonging to .ARG_TYPES" do
      context "when type is defined" do

      end
      context "when type is not defined"
        it "raises an error" do
          @field_definition.args[:id] = "FakeTypeValue"
          expect{@field_definition.validate_arg_types!}.to raise_error
        end
      end
    end
  end

  describe "arg_value_matches_type?" do
    it "returns whether or not the arg value class is included in the defined types" do
      field_definition = described_class.new "stuff", optional_args: {
        id: {type: "Int"},
        name: {type: "String"},
        complete: {type: "Boolean"}
        # address: {type: "AddressType"}
      }

      expect(field_definition.arg_value_matches_type?(:id, 3)).to eq true
      expect(field_definition.arg_value_matches_type?(:id, '3')).to eq false
      expect(field_definition.arg_value_matches_type?(:id, true)).to eq false

      expect(field_definition.arg_value_matches_type?(:name, 'steve')).to eq(
        true
      )
      expect(field_definition.arg_value_matches_type?(:name, 3)).to eq false

      expect(field_definition.arg_value_matches_type?(:complete, true)).to eq(
        true
      )
      expect(field_definition.arg_value_matches_type?(:complete, false)).to eq(
        true
      )
      expect(field_definition.arg_value_matches_type?(:complete, 3)).to eq false

      # expect(field_definition.arg_value_matches_type?(
      #   :address, {street: "To"}
      # )).to eq true
      # expect(field_definition.arg_value_matches_type?(:address, [])).to eq false
      # expect(field_definition.arg_value_matches_type?(:address, true)).to eq(
      #   false
      # )
    end
  end
end
