require "spec_helper"

describe RailsQL::DataType::Base do
  let(:data_type_klass) {Class.new described_class}

  describe ".call_initial_query" do
    it "calls the initial_query proc" do
      query = double
      data_type_klass.initial_query query

      expect(query).to receive(:call)
      data_type_klass.call_initial_query
    end

  end

  describe ".field" do
    context "when data_type exists" do
      it "adds a FieldDefinition to every instance field_definitions" do
        data_type_klass.field(:added_field,
          data_type: RailsQL::DataType::String
        )

        expect(
          data_type_klass.field_definitions[:added_field].class
        ).to eq(
          RailsQL::DataType::FieldDefinition
        )
        expect(
          data_type_klass.field_definitions[:added_field].data_type
        ).to eq(
          RailsQL::DataType::String
        )
      end
    end

    context "when data_type does not exist" do
      it "raises invalid field error" do
        expect{
          data_type_klass.field(:invalid_field,
            data_type: :invalid
          )
        }.to raise_error
      end
    end
  end

  describe "#query" do
    context "when it has no child data_types" do
      it "returns the initial query" do
        data_type_klass.stub(:call_initial_query).and_return :best_query_ever
        expect(data_type_klass.new.query).to eq :best_query_ever
      end
    end

    context "when it has child data_types" do
      it "calls the FieldDefinition#add_to_parent_query" do
        data_type = data_type_klass.new fields: {
          fake_field: data_type_klass.new(args: {id: 3}),
        }
        field_definition = double
        initial_query = double
        data_type_klass.stub(:call_initial_query).and_return initial_query
        allow(data_type_klass).to(
          receive(:field_definitions).and_return fake_field: field_definition
        )

        expect(field_definition).to(
          receive(:add_to_parent_query).with(
            args: {id: 3},
            parent_query: initial_query,
            child_query: initial_query
          )
        )
        data_type.query
      end

      it "reduces over the FieldDefinition#add_to_parent_query results" do
        data_type = data_type_klass.new fields: {
          fake_field_1: data_type_klass.new,
          fake_field_2: data_type_klass.new
        }
        field_definition = double
        initial_query = double
        data_type_klass.stub(:call_initial_query).and_return "the cow says"
        allow(data_type_klass).to(
          receive(:field_definitions).and_return(
            fake_field_1: field_definition,
            fake_field_2: field_definition
          )
        )

        expect(field_definition).to receive(:add_to_parent_query) do |opts|
          opts[:parent_query] + " moo"
        end.twice
        expect(data_type.query).to eq "the cow says moo moo"
      end
    end
  end

  describe "#resolve_child_data_types" do
    it "sets the child DataType's model to the result of the FieldDefinition's resolve method" do
      child_data_type = data_type_klass.new
      data_type = data_type_klass.new fields: {
        fake_field: child_data_type,
      }
      field_definition = double
      allow(data_type_klass).to(
        receive(:field_definitions).and_return(fake_field: field_definition)
      )

      expect(field_definition).to receive(:resolve).and_return :like_whatever
      expect(child_data_type).to receive(:model=).with :like_whatever
      data_type.resolve_child_data_types
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