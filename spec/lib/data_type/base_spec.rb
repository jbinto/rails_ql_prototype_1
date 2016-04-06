require "spec_helper"

describe RailsQL::DataType::Base do
  describe ".model_class_name" do
  end

  describe ".initial_query" do
  end

  describe ".call_initial_query" do
  end

  describe ".field" do
    context "when data_type exists" do
      it "adds a field definition to the data type" do
        RailsQL::DataType::Base.field(:added_field,
          data_type: RailsQL::DataType::String
        )

        expect(
          RailsQL::DataType::Base.field_definitions[:added_field][:data_type]
        ).to eq(
          RailsQL::DataType::String
        )
      end
    end

    context "when data_type does not exist" do
      it "raises invalid field error" do
        expect{
          RailsQL::DataType::Base.field(:invalid_field,
            data_type: :invalid
          )
        }.to raise_error
      end
    end
  end

  describe "#query" do
  end

  describe "#resolve" do
  end

  describe "#to_json" do
  end
end