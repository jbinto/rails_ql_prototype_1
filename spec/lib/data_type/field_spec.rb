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
      parent_data_type: parent_data_type,
      name: "field_name"
    )
  end

  describe "#resolve_models_and_dup_data_type!" do
    context "when #resolve_models is not empty" do
      it "clones the data_type #resolve_models.count times" do
        expect(data_type).to receive(:deep_dup).exactly(3).times.and_return(
          data_type
        )
        expect(data_type).to receive(:fields).exactly(3).times.and_return []
        expect(data_type).to receive(:fields=).exactly(3).times
        allow(data_type).to receive(:model=)
        expect(field).to receive(:resolved_models).and_return [1, 2, 3]

        field.resolve_models_and_dup_data_type!

        expect(field.data_types.count).to eq 3
        expect(field.data_types.first.class).to eq data_type.class
      end
    end

    context "when #resolve_models is empty" do
      before :each do
        allow(field).to receive(:resolved_models).and_return []
      end

      context "when #nullable? is false and #singular? is true" do
        it "raises an error" do
          expect(field).to receive(:nullable?).and_return false
          expect{field.resolve_models_and_dup_data_type!}.to raise_error
        end
      end

      context "when #nullable is true" do
        it "sets data_types to empty array" do
          expect(field).to receive(:nullable?).and_return true
          field.resolve_models_and_dup_data_type!
          expect(field.data_types).to eq []
        end

      end
    end


  end

  describe "#appended_parent_query" do
    context "when field_definition has a query defined" do
      it "instance execs the field_definition#query in the context of the parent data type" do
        args = double
        query = double

        expect(data_type).to receive(:args).and_return args
        expect(data_type).to receive(:query).and_return query
        field_definition_query = ->(actual_args, actual_query){
          [actual_args, actual_query, self]
        }
        expect(field_definition).to receive(:query).twice.and_return(
          field_definition_query
        )

        expect(field.appended_parent_query).to eq [args, query, parent_data_type]
      end
    end

    context "when field_definition does not have a query defined" do
      it "returns the parent_query untouched" do
        expect(parent_data_type).to receive(:query).and_return "parent_query"
        expect(field_definition).to receive(:query).and_return nil
        expect(field.appended_parent_query).to eq "parent_query"
      end
    end
  end

  describe "#resolved_models" do
    before :each do
      field.parent_data_type = parent_data_type
    end

    context "when field_definition has a resolve defined" do
      it "instance execs the field_definition#resolve in the context of the parent data type" do
        args = double
        query = double

        expect(data_type).to receive(:args).and_return args
        expect(data_type).to receive(:query).and_return query
        field_definition_resolve = ->(actual_args, actual_query){
          [actual_args, actual_query, self]
        }
        expect(field_definition).to receive(:resolve).twice.and_return(
          field_definition_resolve
        )

        expect(field.resolved_models).to eq [args, query, parent_data_type]
      end
    end

    context "when field_definition does not have a resolve defined" do
      context "when parent_data_type has the field name defined as a method" do
        it "returns parent_data_type#field_name" do
          # don't use stubs because base does not define field_name
          parent_data_type.instance_eval do
            def field_name
              ["parent_model"]
            end
          end
          expect(field_definition).to receive(:resolve).and_return nil
          expect(field.resolved_models).to eq ["parent_model"]
        end
      end

      context "when parent_data_type does not have the field name defined as a method" do
        it "returns parent_data_type.model#field_name" do
          parent_model = double
          expect(parent_model).to receive(:field_name).and_return(
            ["parent_model"]
          )
          expect(parent_data_type).to receive(:model).and_return(
            parent_model
          )
          expect(field_definition).to receive(:resolve).and_return nil
          expect(field.resolved_models).to eq ["parent_model"]
        end
      end
    end

    context "when the resolution method does not return an array" do
      it "wraps the result in an array" do
        parent_data_type.instance_eval do
          def field_name
            "parent_model"
          end
        end
        expect(field_definition).to receive(:resolve).and_return nil
        expect(field.resolved_models).to eq ["parent_model"]
      end
    end
  end

  describe "#has_read_permission?" do
    it "instance_evals the lambdas of FieldDefinition#read_permissions in the context of the parent_data_type" do
      self_in_lambda = nil
      permission = ->{
        self_in_lambda = self
      }
      expect(field_definition).to receive(:read_permissions).and_return [
        permission
      ]
      field.has_read_permission?
      expect(self_in_lambda).to eq parent_data_type
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
