require "spec_helper"

class ChildDataType < RailsQL::DataType::Base
end

describe RailsQL::DataType::Builder do
  before :each do
    @mocked_data_type = double("DataType", field_definitions: {
        child_data_type: {data_type: ChildDataType}
      }
    )
    @builder = RailsQL::DataType::Builder.new(@mocked_data_type)
  end

  describe "#data_type" do
    it "instantiates a data_type" do
      expect(@mocked_data_type).to receive(:new).with(args: {}, fields: [])
      data_type = @builder.data_type
    end
  end

  describe "#initialize_child" do
    context "when association field exists" do
      context "when no child builder exists" do
        it "intantiates the child builder" do
          @builder.get_child :child_data_type

          child_builder = @builder.child_builders[:child_data_type]
          expect(child_builder.class).to eq RailsQL::DataType::Builder
          expect(child_builder.data_type_klass).to eq ChildDataType
        end
      end

      context "when child builder exists" do
        it "does not instantiate another child builder" do
          child_builder = @builder.get_child(:child_data_type)

          expect(@builder.get_child(:child_data_type)).to eq child_builder
        end
      end
    end

    context "when association field does not exist" do
      it "raises invalid field error" do
        expect{@builder.get_child :invalid_data_type}.to raise_error(
          "Invalid field invalid_data_type"
        )
      end
    end
  end
end