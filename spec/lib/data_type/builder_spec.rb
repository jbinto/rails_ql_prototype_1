require "spec_helper"

describe RailsQL::DataType::Builder do
  before :each do
    stub_const "MockedDataType", Class.new(RailsQL::DataType::Base)
    @mocked_data_type = class_double("MockedDataType")
    @builder = RailsQL::DataType::Builder.new(
      data_type_klass: "mocked_data_type",
      ctx: {},
      root: true
    )
  end

  describe "#data_type_klass" do
    it "constantizes the data_type_klass option" do
      expect(@builder.data_type_klass).to eq MockedDataType
    end
  end

  describe "#data_type" do
    it "instantiates a data_type" do
      allow(@builder).to receive(:data_type_klass).and_return @mocked_data_type
      expect(@mocked_data_type).to receive(:new).with(
        args: {},
        child_data_types: {},
        ctx: {},
        root: true
      )
      data_type = @builder.data_type
    end
  end

  describe "#add_child_builder" do
    before :each do
      allow(@builder).to receive(:data_type_klass).and_return @mocked_data_type
      @field_definition = instance_double RailsQL::DataType::FieldDefinition
      allow(@field_definition).to receive(:data_type).and_return "mocked_data_type"
      allow(@field_definition).to receive(:child_ctx).and_return({})
      allow(@mocked_data_type).to receive(:field_definitions).and_return(
        'child_data_type' => @field_definition
      )
    end
    context "when association field exists" do
      it "intantiates the child builder and adds to builder#child_builders" do
        child_builder = @builder.add_child_builder "child_data_type"

        expect(@builder.child_builders['child_data_type']).to eq child_builder
        expect(child_builder.class).to eq RailsQL::DataType::Builder
        expect(child_builder.data_type_klass).to eq MockedDataType
        expect(child_builder.instance_variable_get("@root")).to eq false
        expect(child_builder.instance_variable_get("@ctx")).to eq({})
      end

      it "merges child_ctx with ctx and passes down to children" do
        expect(@field_definition).to receive(:child_ctx).and_return(
          mega_lasers: :very_yes
        )

        child_builder = @builder.add_child_builder "child_data_type"
        ctx = child_builder.instance_variable_get(:@ctx)

        expect(ctx[:mega_lasers]).to eq :very_yes
      end

      it "is idempotent" do
        child_builder = @builder.add_child_builder "child_data_type"

        expect(@builder.add_child_builder('child_data_type')).to eq child_builder
      end
    end

    context "when association field does not exist" do
      it "raises invalid field error" do
        expect{@builder.add_child_builder 'invalid_data_type'}.to raise_error(
          "Invalid field invalid_data_type"
        )
      end
    end
  end

  describe "#add_arg" do
    it "adds key, value pair to args" do
      @builder.add_arg "string_key", "string_value"
      @builder.add_arg "int_key", 3

      expect(@builder.args['string_key']).to eq "string_value"
      expect(@builder.args['int_key']).to eq 3
    end
  end
end
