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

  describe "#add_read_permission and #readable" do
    it "saves the passed lambda and calls it" do
      field_definition = described_class.new "fake_field_name", data_type: double
      permission = ->{}
      field_definition.add_read_permission permission

      expect(permission).to receive :call

      field_definition.readable?
    end
  end

  describe "#add_to_parent_query" do
    context "when it has a query lambda defined" do
      before :each do
        @query_lamba = double
        @field_definition = described_class.new("fake_field_name",
          data_type: double,
          query: @query_lamba
        )
      end

      it "calls the query lambda with the args, parent_query, child_query" do
        opts = {
          args: {},
          parent_query: double,
          child_query: double
        }

        expect(@query_lamba).to(
          receive(:call).with(*opts.values).and_return "dank_memes"
        )
        result = @field_definition.add_to_parent_query opts
        expect(result).to eq "dank_memes"
      end
    end

    context "when it does not have a query lambda defined" do
      before :each do
        @field_definition = described_class.new("fake_field_name",
          data_type: double
        )
      end

      it "returns parent_query" do
        opts = {
          args: {},
          parent_query: double,
          child_query: double
        }

        results = @field_definition.add_to_parent_query opts

        expect(results).to eq opts[:parent_query]
      end
    end
  end

  describe "#resolve" do
    before :each do
      @data_type = double
      @model = double
    end

    context "when it does not have a :resolve lambda defined" do
      before :each do
        @field_definition = described_class.new("fake_field_name",
          data_type: double
        )
      end

      it "returns the parent data type's field if one is present" do
        allow(@data_type).to receive(:fake_field_name).and_return "dank_memes"

        result = @field_definition.resolve(
          parent_data_type: @data_type,
          parent_model: @model
        )
        expect(result).to eq "dank_memes"
      end

      it "returns the parent model's field if it is not defined on the data type" do
        allow(@model).to receive(:fake_field_name).and_return "dank_memes"

        result = @field_definition.resolve(
          parent_data_type: @data_type,
          parent_model: @model
        )
        expect(result).to eq "dank_memes"
      end
    end

    context "when it does have a :resolve lambda defined" do
      it "calls the resolve lambda with the model" do
        @resolve_lambda = double
        @field_definition = described_class.new("fake_field_name",
          data_type: double,
          resolve: @resolve_lambda
        )

        expect(@resolve_lambda).to(
          receive(:call).with(@model).and_return "dank_memes"
        )
        result = @field_definition.resolve(
          parent_data_type: @data_type,
          parent_model: @model
        )
        expect(result).to eq "dank_memes"
      end
    end
  end

end
