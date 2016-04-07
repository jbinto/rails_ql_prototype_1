require "spec_helper"

describe RailsQL::DataType::Builder do
  before :each do
    @mocked_data_type = double("DataType")
    allow(@mocked_data_type).to receive(:field_definitions).and_return(
      child_data_type: {data_type: @mocked_data_type}
    )
    @builder = RailsQL::DataType::Builder.new(@mocked_data_type)
  end

  describe "#data_type" do
    it "instantiates a data_type" do
      expect(@mocked_data_type).to receive(:new).with(args: {}, fields: [])
      data_type = @builder.data_type
    end
  end

  describe "#add_child_builder" do
    context "when association field exists" do
      it "intantiates the child builder and adds to builder#child_builders" do
        child_builder = @builder.add_child_builder :child_data_type

        expect(@builder.child_builders[:child_data_type]).to eq child_builder
        expect(child_builder.class).to eq RailsQL::DataType::Builder
        expect(child_builder.data_type_klass).to eq @mocked_data_type
      end

      it "is idempotent" do
        child_builder = @builder.add_child_builder(:child_data_type)

        expect(@builder.add_child_builder(:child_data_type)).to eq child_builder
      end
    end

    context "when association field does not exist" do
      it "raises invalid field error" do
        expect{@builder.add_child_builder :invalid_data_type}.to raise_error(
          "Invalid field invalid_data_type"
        )
      end
    end
  end

  describe "#add_arg" do
    it "adds key, value pair to args" do
      @builder.add_arg "string_key", "string_value"
      @builder.add_arg "int_key", 3

      expect(@builder.args['string_key']).to eq "string_value"
      expect(@builder.args['int_key']).to eq 3
    end
  end
end