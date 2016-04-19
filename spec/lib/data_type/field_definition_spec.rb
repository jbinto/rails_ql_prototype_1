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
        @field_definition.optional_args[:id] = "FakeValue"
        expect{@field_definition.validate_arg_types!}.to raise_error
      end
    end
  end

end
