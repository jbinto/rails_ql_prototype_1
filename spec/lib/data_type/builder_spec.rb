require "spec_helper"

class ChildDataType < RailsQL::DataType::Base
end

describe RailsQL::DataType::Builder do
  before :each do
    # @base = RailsQL::DataType::Base.new(
      # field_definitions: {
      #   data_type: :child_data_type,
      #   args: [:id],
      #   resolve: ->(args, child_query) { model.send(:my_association_name) },
      #   query: ->(args, child_query) { return query.where(id: args[:id]) },
      #   description: "my association description",
      #   nullable: true
      # }
    # )
    mocked_data_type = double("DataType", field_definitions: {
        data_type: :child_data_type
      }
    )
    @builder = RailsQL::DataType::Builder.new(mocked_data_type)
    p @builder
  end

  describe "#"

  describe "#initialize_child" do
    context "when association field exists" do
      context "when no child builder exists" do
        it "intantiates the child builder" do
          @builder.get_child :child_data_type

          child_builder = @builder.children[:child_data_type]
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