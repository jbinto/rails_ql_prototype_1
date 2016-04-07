require "spec_helper"

describe RailsQL::DataType::Base do
  describe ".model_class_name" do
  end

  describe ".initial_query" do
  end

  describe ".call_initial_query" do
    it "calls the initial_query proc" do
      initial_query = double()
      RailsQL::DataType::Base.instance_variable_set(
        :@initial_query, initial_query
      )
      expect(initial_query).to receive(:call)

      RailsQL::DataType::Base.call_initial_query
    end

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
    pending
    fail
  end

  describe "#resolve" do
    pending
    fail
  end

  describe "#to_json" do
    before :each do
      # @base = RailsQL::DataType::Base.new(
      #   fields: {
      #     base_1: RailsQL::DataType::Base.new(
      #       fields: {name: {data_type: RailsQL::DataType::String, model: "name_1"}}
      #     ),
      #     base_2: RailsQL::DataType::Base.new(
      #       fields: {name: {data_type: RailsQL::DataType::String, model: "name_2"}}
      #     )
      #   }
      # )
    end

    it "recursively calls to_json on all fields" do
      pending
      fail
      # @base.to_json
    end
  end
end