require "spec_helper"

describe RailsQL::Field::FieldDefinitionCollection do

    let(:collection) {
      described_class.new
    }


  describe "#add_field_definition" do
    it "adds field definitions" do
      # field_definition = instance_double RailsQL::Field::FieldDefinition
      expect(RailsQL::Field::FieldDefinition).to receive(:new).with(:superhero, {})
        # .and_return(field_definition)
      # allow(field_definition).to receive(:add_permission)

      collection.add_field_definition "superhero", {}
    end

    it "adds introspection fields prefixed with __" do
      expect(RailsQL::Field::FieldDefinition).to receive(:new).with(
        :__secret, {introspection: true}
      )

      collection.add_field_definition "__secret", {introspection: true}
    end

    it "does not add non-introspection fields prefixed with __" do
      expect{
        collection.add_field_definition "__secret", {}
      }.to raise_error(RailsQL::InvalidField, /names must not be prefixed with double underscores/)
    end

    context "for reserved field names" do
      it "raises an error" do
        expect{
          collection.add_field_definition "to_s", {}
        }.to raise_error(RailsQL::InvalidField, /Can not use to_s as a field name/)
      end

      it "does not raise an error when a custom :resolve option is provided" do
        expect{
          collection.add_field_definition "to_s", {resolve: ->(){} }
        }.to_not raise_error(RailsQL::InvalidField, /Can not use to_s as a field name/)
      end
    end

    # klass.add_field_definition :example_field, type: class_double()
    # klass.has_one :child_type, type: klass
    # klass
  end

  describe "#add_plural_field_definition" do
    it "calls #add_field_definition with singular: false" do
      expect(RailsQL::Field::FieldDefinition).to receive(:new).with(
        :superhero, { singular: false, some_option: true }
      )
      collection.add_plural_field_definition "superhero", { some_option: true }
    end
  end

  describe "#add_permissions" do
    context "for valid fields" do
      def add_mock_field_definition(name)
        field_definition = instance_double RailsQL::Field::FieldDefinition
        expect(RailsQL::Field::FieldDefinition).to receive(:new).with(name.to_sym, {})
          .and_return(field_definition)
        collection.add_field_definition name, {}
        return field_definition
      end

      it "adds a single permission to a single field" do
        # first, set up a FieldDefinition or we have nothing to add_permissions to
        superhero_field_definition = add_mock_field_definition "superhero"

        # now, assert that our `field_definition` had `add_permissions` called on it
        expect(superhero_field_definition).to receive(:add_permission).with(
          :query,
          anything    # e.g. opts[:when] default lambda
        )
        collection.add_permissions :query, {
          fields: ["superhero"]
        }
      end

      it "adds multiple permissions (eg. input and query) to multiple fields" do
        # first, set up a few FieldDefinitions or we have nothing to add_permissions to
        superhero_field_definition = add_mock_field_definition "superhero"
        villian_field_definition = add_mock_field_definition "villian"

        # now, assert that all of our `field_definition`s had `add_permission` called on it
        # multiple times, once for each operation
        expect(superhero_field_definition).to receive(:add_permission).with(:query, anything)
        expect(superhero_field_definition).to receive(:add_permission).with(:mutate, anything)

        expect(villian_field_definition).to receive(:add_permission).with(:query, anything)
        expect(villian_field_definition).to receive(:add_permission).with(:mutate, anything)

        collection.add_permissions [:query, :mutate], {
          fields: ["superhero", "villian"]
        }
      end
    end

    context "for undefined fields" do
      it "raises an error" do
        expect{
          collection.add_permissions :query, {
            fields: ["bogus"]
          }
        }.to raise_error(RailsQL::FieldMissing, /The field bogus was not defined/)
      end
    end
  end

end
