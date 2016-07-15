require "spec_helper"

describe RailsQL::Field::Field do
  let(:input_field_definition){instance_double(
    RailsQL::Type::InputFieldDefinition
  )}

  let(:input_obj_klass) do
    klass = class_double RailsQL::Type::InputObject
    # allow(klass).to receive(input_field_definitions).and_return(
    #   random_arg_field: input_field_definition
    # )
  end

  let(:field_definition) do
    definition = instance_double RailsQL::Field::FieldDefinition
    allow(definition).to receive(:args).and_return input_obj_klass
    definition
  end

  let(:type) do
    type = instance_double RailsQL::Type::Type
    allow(type).to receive(:args).and_return({})
    type
  end

  let(:parent_type) do
    instance_double RailsQL::Type::Type
  end

  let(:field) do
    described_class.new(
      field_definition: field_definition,
      type: type,
      parent_type: parent_type,
      name: "field_name"
    )
  end

  describe "#validate_args!" do
    it "calls field_definition#args#validate_input_args! with the type args" do
      field
      allow(field).to receive(:type_args).and_return(random_arg_field: 3)
      expect(field_definition).to receive(:args).and_return input_obj_klass
      expect(input_obj_klass).to receive(:validate_input_args!).with(
        random_arg_field: 3
      )

      field.validate_args!
    end
  end

  describe "#resolve_models_and_dup_type!" do
    context "when #resolve_models is not empty" do
      it "clones the type #resolve_models.count times" do
        expect(type).to receive(:deep_dup).exactly(3).times.and_return(
          type
        )
        expect(type).to receive(:fields).exactly(3).times.and_return []
        expect(type).to receive(:fields=).exactly(3).times
        allow(type).to receive(:model=)
        expect(field).to receive(:resolved_models).and_return [1, 2, 3]

        field.resolve_models_and_dup_type!

        expect(field.types.count).to eq 3
        expect(field.types.first.class).to eq type.class
      end
    end

    context "when #resolve_models is empty" do
      before :each do
        allow(field).to receive(:resolved_models).and_return []
      end

      context "when #nullable? is false and #singular? is true" do
        it "raises an error" do
          expect(field).to receive(:nullable?).and_return false
          expect{field.resolve_models_and_dup_type!}.to raise_error
        end
      end

      context "when #nullable is true" do
        it "sets types to empty array" do
          expect(field).to receive(:nullable?).and_return true
          field.resolve_models_and_dup_type!
          expect(field.types).to eq []
        end

      end
    end


  end

  describe "#appended_parent_query" do
    before :each do
      field.parent_type = parent_type
    end

    it "calls field_definition#append_to_query" do
      args = double
      query = double

      expect(field).to receive(:type_args).and_return args
      expect(type).to receive(:query).and_return query
      expect(field_definition).to receive(:append_to_query).with(
        parent_type: parent_type,
        args: args,
        child_query: query
      )

      field.appended_parent_query
    end
  end

  describe "#resolved_models" do
    before :each do
      field.parent_type = parent_type
    end

    it "calls field_definition#resolve" do
      args = double
      query = double

      expect(field).to receive(:type_args).and_return args
      expect(type).to receive(:query).and_return query
      expect(field_definition).to receive(:resolve).with(
        parent_type: parent_type,
        args: args,
        child_query: query
      )

      field.resolved_models
    end

    context "when the resolution method does not return an array" do
      it "wraps the result in an array" do
        args = double
        query = double
        allow(field).to receive(:type_args).and_return args
        allow(type).to receive(:query).and_return query
        allow(field_definition).to receive(:resolve).and_return "parent_model"

        expect(field.resolved_models).to eq ["parent_model"]
      end
    end
  end

  describe "#has_read_permission?" do
    it "instance_evals the lambdas of FieldDefinition#read_permissions in the context of the parent_type" do
      self_in_lambda = nil
      permission = ->{
        self_in_lambda = self
      }
      expect(field_definition).to receive(:read_permissions).and_return [
        permission
      ]
      field.has_read_permission?
      expect(self_in_lambda).to eq parent_type
    end

    context "when any permission evaluates to true" do
      it "returns true" do
          expect(field_definition).to receive(:read_permissions).and_return [
            ->{false},
            ->{true},
            ->{false}
          ]
          expect(field.has_read_permission?).to eq true
      end
    end

    context "when all permissions evaluates to false" do
      it "returns false" do
          expect(field_definition).to receive(:read_permissions).and_return [
            ->{false}
          ]
          expect(field.has_read_permission?).to eq false
      end
    end

    context "when there are no permissions" do
      it "returns false" do
          expect(field_definition).to receive(:read_permissions).and_return [
          ]
          expect(field.has_read_permission?).to eq false
      end
    end

  end

end
