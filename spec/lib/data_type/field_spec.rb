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

  describe "#resolved_model" do
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

        expect(field.resolved_model).to eq [args, query, parent_data_type]
      end
    end

    context "when field_definition does not have a resolve defined" do
      context "when parent_data_type has the field name defined as a method" do
        it "returns parent_data_type#field_name" do
          # don't use stubs because base does not define field_name
          parent_data_type.instance_eval do
            def field_name
              "parent_model"
            end
          end
          expect(field_definition).to receive(:resolve).and_return nil
          expect(field.resolved_model).to eq "parent_model"
        end
      end

      context "when parent_data_type does not have the field name defined as a method" do
        it "returns parent_data_type.model#field_name" do
          parent_model = double
          expect(parent_model).to receive(:field_name).and_return(
            "parent_model"
          )
          expect(parent_data_type).to receive(:model).and_return(
            parent_model
          )
          expect(field_definition).to receive(:resolve).and_return nil
          expect(field.resolved_model).to eq "parent_model"
        end
      end
    end
  end

  describe "#has_read_permission?" do
  end

end
