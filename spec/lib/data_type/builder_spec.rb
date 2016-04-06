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

  describe "#add_child" do
    context "when association field exists" do
      it "intantiates the child builder" do
        @builder.add_child :child_data_type

        child_builder = @builder.child_builders[:child_data_type]
        expect(child_builder.class).to eq RailsQL::DataType::Builder
        expect(child_builder.data_type_klass).to eq @mocked_data_type
      end

      it "is idempotent" do
        child_builder = @builder.add_child(:child_data_type)

        expect(@builder.add_child(:child_data_type)).to eq child_builder
      end
    end

    context "when association field does not exist" do
      it "raises invalid field error" do
        expect{@builder.add_child :invalid_data_type}.to raise_error(
          "Invalid field invalid_data_type"
        )
      end
    end
  end
end