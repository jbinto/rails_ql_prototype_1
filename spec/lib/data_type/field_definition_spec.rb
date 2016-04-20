require "spec_helper"

describe RailsQL::DataType::FieldDefinition do
  describe "#read_permission_lambda" do
    context "when permissions have been added" do
      it "returns the list of read permissions" do
        field_definition = described_class.new "stuff", data_type: double
        permission = double
        field_definition.add_read_permission permission

        expect(field_definition.read_permissions).to eq [permission]
      end
    end

    context "when no permissions have been set" do
      it "returns an array of one lambda which evaluates to false" do
        field_definition = described_class.new "stuff", data_type: double

        expect(field_definition.read_permissions[0].call).to eq false
      end
    end
  end

  describe "#validate_arg_types!" do
    before :each do
      @field_definition = described_class.new "stuff", optional_args: {
        id: "IntValue"
      }
    end

    context "when optional or required args have types belonging to .ARG_TYPES" do
      it "does not raise an error" do
        expect{@field_definition.validate_arg_types!}.to_not raise_error
      end
    end

    context "when optional or required args have types not belonging to .ARG_TYPES" do
      it "raises an error" do
        @field_definition.optional_args[:id] = "FakeTypeValue"
        expect{@field_definition.validate_arg_types!}.to raise_error
      end
    end
  end

  describe "arg_value_matches_type?" do
    it "returns whether or not the arg value class is included in the defined types" do
      field_definition = described_class.new "stuff", optional_args: {
        id: "IntValue",
        name: "StringValue",
        complete: "BooleanValue",
        address: "ObjectValue"
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

      expect(field_definition.arg_value_matches_type?(
        :address, {city: "To"}
      )).to eq true
      expect(field_definition.arg_value_matches_type?(:address, [])).to eq false
      expect(field_definition.arg_value_matches_type?(:address, true)).to eq(
        false
      )
    end
  end

end
