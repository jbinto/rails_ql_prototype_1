require "spec_helper"

describe RailsQL::DataType::Field do
  let(:field_definition) do
    instance_double RailsQL::DataType::FieldDefinition
  end

  let(:data_type) do
    instance_double RailsQL::DataType::Base
  end

  let(:parent_data_type) do
    instance_double RailsQL::DataType::Base
  end

  let(:field) do
    described_class.new(
      field_definition: field_definition,
      data_type: data_type,
      parent_data_type: parent_data_type
    )
  end

  describe "#add_to_parent_query!" do
    context "when field_definition has a query defined" do
      it "calls build_query! on the data_type" do
        pending
        fail
      end

      it "instance execs the field_definition#query in the context of the parent data type" do
        # expect(field_definition).to receive(:query).and_return "parent_query"
        args = double
        query = double

        expect(data_type).to receive(:args).and_return args
        expect(data_type).to receive(:query).and_return query
        query = ->(actual_args, actual_query){ p actual_query; [actual_args, actual_query, self] }
        expect(field_definition).to receive(:query).twice.and_return query
        expect(query).to receive :call


        expect(field.add_to_parent_query!).to eq [args, query, parent_data_type]
      end
    end

    context "when field_definition does not have a query defined" do
      it "returns the parent_query untouched" do
        expect(parent_data_type).to receive(:query).and_return "parent_query"
        expect(field.add_to_parent_query!).to eq "parent_query"
      end
    end
  end

  describe "#resolve!" do
  end

  describe "#has_read_permission?" do
  end

end
