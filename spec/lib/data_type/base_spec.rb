require "spec_helper"

describe RailsQL::DataType::Base do
  let(:data_type_klass) {Class.new described_class}

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

  describe "#build_query!" do
    context "when it has no child data_types" do
      it "returns the initial query" do
        allow(data_type_klass).to receive(:get_initial_query).and_return(
          ->{:best_query_ever}
        )
        expect(data_type_klass.new.build_query!).to eq :best_query_ever
      end
    end

    context "when it has fields" do
      it "calls Field#appended_parent_query and saves results to query" do
        field = instance_double RailsQL::DataType::Field
        data_type = data_type_klass.new
        allow(data_type).to receive(:fields).and_return(fake_field: field)
        child_data_type = instance_double described_class
        allow(field).to receive(:data_type).and_return(
          child_data_type
        )
        allow(child_data_type).to receive :build_query!
        allow(data_type_klass).to receive(:get_initial_query).and_return double

        expect(field).to receive(:appended_parent_query).and_return :lions
        data_type.build_query!
        expect(data_type.query).to eq :lions
      end

      it "reduces over the Field#appended_parent_query results" do
        fields = {
          fake_field_1: instance_double(RailsQL::DataType::Field),
          fake_field_2: instance_double(RailsQL::DataType::Field)
        }
        allow(data_type_klass).to receive(:get_initial_query).and_return(
          -> {"the cow says"}
        )
        data_type = data_type_klass.new
        allow(data_type).to receive(:fields).and_return fields

        fields.each do |k, field|
          allow(field).to(
            receive_message_chain(:data_type, :build_query!).and_return(
              double
            )
          )
          expect(field).to receive(:appended_parent_query) do
            data_type.query + " moo"
          end.once
        end
        expect(data_type.build_query!).to eq "the cow says moo moo"
      end
    end
  end

  describe "#resolve_child_data_types!" do
    it "calls Field#resolved_model for each field and saves the model to the field" do
      field = instance_double RailsQL::DataType::Field
      data_type = data_type_klass.new
      allow(data_type).to receive(:fields).and_return(fake_field: field)

      field_data_type = instance_double described_class
      allow(field_data_type).to receive :resolve_child_data_types!
      allow(field).to receive(:data_type).and_return field_data_type

      expect(field).to receive(:resolved_model).and_return :the_pope
      expect(field.data_type).to receive(:model=).with(
        :the_pope
      )
      data_type.resolve_child_data_types!
    end

    it "calls resolve_child_data_types! on child_data_types" do
      field = instance_double RailsQL::DataType::Field
      data_type = data_type_klass.new
      allow(data_type).to receive(:fields).and_return(fake_field: field)
      field_data_type = instance_double described_class
      allow(field).to receive(:data_type).and_return field_data_type
      allow(field).to receive :resolved_model
      allow(field.data_type).to receive :model=

      expect(field_data_type).to receive :resolve_child_data_types!


      data_type.resolve_child_data_types!
    end

    it "runs resolve callbacks" do
      data_type = data_type_klass.new

      expect do |b|
        data_type_klass.before_resolve &b
        data_type.resolve_child_data_types!
      end.to yield_control
    end

  end

  describe "#as_json" do
    it "reduces over #as_json on fields" do
      field = instance_double RailsQL::DataType::Field
      data_type = data_type_klass.new
      allow(data_type).to receive(:fields).and_return(
        fake_field_1: field,
        fake_field_2: field
      )
      allow(field).to receive_message_chain(:data_type, :as_json).and_return(
        "hello" => "world"
      )

      expect(data_type.as_json).to eq(
        "fake_field_1" => {"hello" => "world"},
        "fake_field_2" => {"hello" => "world"}
      )
    end
  end
end