require "spec_helper"

describe RailsQL::DataType::FieldDefinition do

  describe "#initialize" do
    it "raises an error if the :data_type option is missing" do
      expect{
        described_class.new("fake_field_name", {})
      }.to raise_error
    end
    it "does not raise an error if the :data_type is defined" do
      expect{
        described_class.new("fake_field_name", {data_type: double})
      }.not_to raise_error
    end
  end

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

end
