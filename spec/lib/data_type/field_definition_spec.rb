require "spec_helper"

describe RailsQL::DataType::FieldDefinition do
  describe "#initialize" do

    {
      required_args: :hash,
      optional_args: :hash,
      child_ctx: :hash,
      resolve: :lambda,
      query: :lambda
    }.each do |opt_name, type|
      it "throws an error if :#{opt_name} is not a #{type}" do
        expect{
          described_class.new "things", data_type: double, opt_name => "dinosaur"
        }.to raise_error
      end
    end

  end

  describe "#read_permission_lambda" do
    context "when permissions have been added" do
      it "returns the list of read permissions" do
        field_definition = described_class.new "stuff", data_type: double
        permission = double
        field_definition.add_read_permission permission

        expect(field_definition.read_permissions).to eq [permission]
      end
    end

    context "when no permissions have been set" do
      it "returns an array of one lambda which evaluates to false" do
        field_definition = described_class.new "stuff", data_type: double

        expect(field_definition.read_permissions[0].call).to eq false
      end
    end
  end

  describe "#validate_arg_types!" do
    before :each do
      @field_definition = described_class.new "stuff", optional_args: {
        id: {type: "Int", description: "The identifier value"}
      }
    end

    context "when optional or required args have types belonging to .ARG_TYPES" do
      it "does not raise an error" do
        expect{@field_definition.validate_arg_types!}.to_not raise_error
      end
    end

    context "when optional or required args have types not belonging to .ARG_TYPES" do
      it "raises an error" do
        @field_definition.optional_args[:id] = "FakeTypeValue"
        expect{@field_definition.validate_arg_types!}.to raise_error
      end
    end
  end

  describe "arg_value_matches_type?" do
    it "returns whether or not the arg value class is included in the defined types" do
      field_definition = described_class.new "stuff", optional_args: {
        id: {type: "Int"},
        name: {type: "String"},
        complete: {type: "Boolean"}
        # address: {type: "AddressType"}
      }

      expect(field_definition.arg_value_matches_type?(:id, 3)).to eq true
      expect(field_definition.arg_value_matches_type?(:id, '3')).to eq false
      expect(field_definition.arg_value_matches_type?(:id, true)).to eq false

      expect(field_definition.arg_value_matches_type?(:name, 'steve')).to eq(
        true
      )
      expect(field_definition.arg_value_matches_type?(:name, 3)).to eq false

      expect(field_definition.arg_value_matches_type?(:complete, true)).to eq(
        true
      )
      expect(field_definition.arg_value_matches_type?(:complete, false)).to eq(
        true
      )
      expect(field_definition.arg_value_matches_type?(:complete, 3)).to eq false

      # expect(field_definition.arg_value_matches_type?(
      #   :address, {street: "To"}
      # )).to eq true
      # expect(field_definition.arg_value_matches_type?(:address, [])).to eq false
      # expect(field_definition.arg_value_matches_type?(:address, true)).to eq(
      #   false
      # )
    end
  end

  describe "#append_to_query" do
    context "when field_definition has a query defined" do
      it "instance execs the field_definition#query in the context of the parent data type" do
        data_type = instance_double RailsQL::DataType::Base
        args = {}
        query = double

        field_definition_query = ->(actual_args, actual_query){
          [actual_args, actual_query, self]
        }
        field_definition = described_class.new("stuff",
          query: field_definition_query
        )

        expect(field_definition.append_to_query(
          parent_data_type: data_type,
          args: args,
          child_query: query
        )).to eq [args, query, data_type]
      end
    end

    context "when field_definition does not have a query defined" do
      it "returns the parent_query untouched" do
        data_type = instance_double RailsQL::DataType::Base
        expect(data_type).to receive(:query).and_return "parent_query"
        field_definition = described_class.new "stuff", query: nil

        expect(field_definition.append_to_query(
          parent_data_type: data_type,
          args: double,
          child_query: double
        )).to eq "parent_query"
      end
    end
  end

  describe "#resolve" do
    context "when field_definition has a resolve defined" do
      it "instance execs the field_definition#resolve in the context of the parent data type" do
        data_type = instance_double RailsQL::DataType::Base
        args = {}
        query = double

        field_definition_resolve = ->(actual_args, actual_query){
          [actual_args, actual_query, self]
        }
        field_definition = described_class.new("stuff",
          resolve: field_definition_resolve
        )

        expect(field_definition.resolve(
          parent_data_type: data_type,
          args: args,
          child_query: query
        )).to eq [args, query, data_type]
      end
    end

    context "when field_definition does not have a resolve defined" do
      context "when parent_data_type has the field name defined as a method" do
        it "returns parent_data_type#field_name" do
          data_type = instance_double RailsQL::DataType::Base
          # don't use stubs because base does not define field_name
          data_type.instance_eval do
            def stuff
              "parent_model"
            end
          end
          field_definition = described_class.new "stuff", resolve: nil

          expect(field_definition.resolve(
            parent_data_type: data_type,
            args: double,
            child_query: double
          )).to eq "parent_model"
        end
      end

      context "when parent_data_type does not have the field name defined as a method" do
        it "returns parent_data_type.model#field_name" do
          parent_model = double
          expect(parent_model).to receive(:stuff).and_return(
            "parent_model_field"
          )
          data_type = instance_double RailsQL::DataType::Base
          expect(data_type).to receive(:model).twice.and_return parent_model
          field_definition = described_class.new "stuff", resolve: nil

          expect(field_definition.resolve(
            parent_data_type: data_type,
            args: double,
            child_query: double
          )).to eq "parent_model_field"
        end
      end
    end
  end

end
