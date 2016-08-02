require "spec_helper"

describe RailsQL::Field::FieldDefinitionCollection do

    let(:collection) {
      described_class.new
    }


  describe "#add_field_definition"
    it "adds field definitions" do

    end

    it "adds introspection fields prefixed with __" do
    end

    it "does not add non-introspection fields prefixed with __" do
    end

    context "for reserved field names" do
      it "raises an error" do

      end
    end

    # klass.add_field_definition :example_field, type: class_double()
    # klass.has_one :child_type, type: klass
    # klass
  end

  describe "#add_plural_field_definition" do
    it "calls #add_field_definition with singular: false" do
    end
  end

  describe "#add_permissions" do
    context "for valid fields" do
      it "adds a single permission to a field" do

      end

      it "adds multiple permissions (eg. input and query) to multiple fields" do

      end
    end

    context "for undefined fields" do
      it "raises an error" do

      end
    end
  end

end
