require "spec_helper"

describe RailsQL::DataType::FieldDefinition do

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
end