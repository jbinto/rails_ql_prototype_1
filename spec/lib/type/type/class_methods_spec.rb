require "spec_helper"

describe RailsQL::Type do
  let(:type_klass) {Class.new described_class}

  describe ".field" do
    context "when a type option is passed" do
      it "adds a FieldDefinition" do
        child_type = instance_double described_class
        field_def_klass = class_double("RailsQL::Field::FieldDefinition")
          .as_stubbed_const
        field_definition = double

        expect(field_def_klass).to receive(:new).with(:added_field,
          type: child_type
        ).and_return field_definition

        type_klass.field :added_field, type: child_type

        expect(type_klass.field_definitions[:added_field]).to eq(
          field_definition
        )
      end
    end

    context "when name is prefixed by double underscores" do
      it "raises an error" do
        expect{
          type_klass.field(:__field_name,
            type: double
          )
        }.to raise_error
      end
    end

    context "when name is reserved" do
      it "raises an error" do
        expect{
          type_klass.field(:query,
            type: double
          )
        }.to raise_error
      end
    end

    context "when a name is defined on the Type subclass" do
      it "does not raise an error" do
        type_klass.class_eval do
          def example_field
          end
        end

        expect{
          type_klass.field(:example_field,
            type: double
          )
        }.to_not raise_error
      end
    end
  end

  describe ".kind" do
    context "when passed a valid kind symbol" do
      it "sets the kind" do
        type_klass.kind :OBJECT

        results = type_klass.type_definition.kind

        expect(results).to eq :OBJECT
      end
    end

    context "when passed an invalid kind" do
      it "raises an error" do
        expect{type_klass.kind(:MEGA_SHARK)}.to raise_error
      end
    end

    context "when kind is not set" do
      context "without args" do
        it "returns the OBJECT kind" do
          results = type_klass.type_definition.kind

          expect(results).to eq :OBJECT
        end
      end
    end
  end

  shared_examples "type_association" do |method_sym, singular|
    it "aliases .field" do
      field_def_klass = class_double("RailsQL::Field::FieldDefinition")
        .as_stubbed_const
      field_definition = double
      expect(field_def_klass).to receive(:new).with(:cows_and_stuff,
        type: :reasons,
        singular: singular
      ).and_return field_definition
      type_klass.send method_sym, :cows_and_stuff, type: :reasons
    end
  end

  describe ".has_many" do
    it_behaves_like "type_association", :has_many, false
  end

  describe ".has_one" do
    it_behaves_like "type_association", :has_one, true
  end

end
