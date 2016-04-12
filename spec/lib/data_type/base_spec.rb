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

  describe ".field_definitions" do
    it "returns a list of field definitions" do
      pending
      fail
    end
  end

  describe ".field" do
    context "when a data_type option is passed" do
      it "adds a FieldDefinition" do
        child_data_type = instance_double described_class
        field_def_klass = class_double("RailsQL::DataType::FieldDefinition")
          .as_stubbed_const
        field_definition = double

        expect(field_def_klass).to receive(:new).with(:added_field,
          data_type: child_data_type
        ).and_return field_definition

        data_type_klass.field :added_field, data_type: child_data_type

        expect(data_type_klass.field_definitions[:added_field]).to eq(
          field_definition
        )
      end
    end

    context "when data_type is nil" do
      it "raises an error" do
        expect{
          data_type_klass.field(:invalid_field,
            data_type: nil
          )
        }.to raise_error
      end
    end

    context "when name is reserved" do
      it "raises an error" do
        expect{
          data_type_klass.field(:query,
            data_type: double
          )
        }.to raise_error
      end
    end

    context "when a name is defined on the DataType subclass" do
      it "does not raise an error" do
        data_type_klass.class_eval do
          def example_field
          end
        end

        expect{
          data_type_klass.field(:example_field,
            data_type: double
          )
        }.to_not raise_error
      end
    end
  end

  shared_examples "data_type_association" do |method_sym|
    it "aliases .field" do
      field_def_klass = class_double("RailsQL::DataType::FieldDefinition")
        .as_stubbed_const
      field_definition = double
      expect(field_def_klass).to receive(:new).with(:cows_and_stuff,
        data_type: :reasons
      ).and_return field_definition
      data_type_klass.send method_sym, :cows_and_stuff, data_type: :reasons
    end
  end

  describe ".has_many" do
    it_behaves_like "data_type_association", :has_many
  end

  describe ".has_one" do
    it_behaves_like "data_type_association", :has_one
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

    it "runs resolve callbacks" do
      data_type = data_type_klass.new

      expect do |b|
        data_type_klass.before_resolve &b
        data_type.resolve_child_data_types
      end.to yield_control
    end

  end

  describe "#as_json" do
    it "reduces over #as_json on fields" do
      child_data_type = instance_double described_class
      data_type = data_type_klass.new fields: {
        fake_field_1: child_data_type,
        fake_field_2: child_data_type
      }

      expect(child_data_type).to receive(:as_json).and_return(
        hello: "world"
      ).twice
      expect(data_type.as_json).to eq(
        fake_field_1: {hello: "world"},
        fake_field_2: {hello: "world"}
      )
    end
  end
end