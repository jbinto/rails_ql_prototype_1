require "spec_helper"

describe RailsQL::DataType::Base do
  let(:data_type) {Class.new described_class}
  describe ".model_class_name" do
  end

  describe ".initial_query" do
  end

  describe ".call_initial_query" do
    it "calls the initial_query proc" do
      query = double
      data_type.initial_query query

      expect(query).to receive(:call)
      data_type.call_initial_query
    end

  end

  describe ".field" do
    context "when data_type exists" do
      it "adds a FieldDefinition to every instance field_definitions" do
        data_type.field(:added_field,
          data_type: RailsQL::DataType::String
        )

        expect(
          data_type.field_definitions[:added_field].class
        ).to eq(
          RailsQL::DataType::FieldDefinition
        )
        expect(
          data_type.field_definitions[:added_field].data_type
        ).to eq(
          RailsQL::DataType::String
        )
      end
    end

    context "when data_type does not exist" do
      it "raises invalid field error" do
        expect{
          data_type.field(:invalid_field,
            data_type: :invalid
          )
        }.to raise_error
      end
    end
  end

  describe "#query" do
    context "when it has no child data_types" do
      it "returns the initial query" do
        pending
        fail
      end
    end

    context "when it has child data_types" do
      it "calls the FieldDefinition#add_to_parent_query" do
        field_definition = double

      end

      it "reduces over the FieldDefinition#add_to_parent_query results" do
      end
    end
  end

  describe "#resolve_child_data_types" do
    context "when it has no child data_types" do
      it "it does nothing" do
        pending
        fail
      end
    end

    context "when it has child data_types" do
      it "calls the type definition's :resolve lambda with the model" do
      end

      it "sets the child datat type's model to the result of the type definition's :revolve lambda" do
      end

      it "skips over type definitions without resolve lambdas in the reducer" do
      end
    end
  end

  describe "#to_json" do
    before :each do
      # @base = data_type.new(
      #   fields: {
      #     base_1: data_type.new(
      #       fields: {name: {data_type: RailsQL::DataType::String, model: "name_1"}}
      #     ),
      #     base_2: data_type.new(
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