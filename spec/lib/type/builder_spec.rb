require "spec_helper"

describe RailsQL::Type::Builder do
  before :each do
    stub_const "MockedType", Class.new(RailsQL::Type::Type)
    @mocked_type = class_double("MockedType")
    @builder = RailsQL::Type::Builder.new(
      type_klass: "mocked_type",
      ctx: {},
      root: true
    )
  end

  describe "#type_klass" do
    it "constantizes the type_klass option" do
      expect(@builder.type_klass).to eq MockedType
    end
  end

  describe "#type" do
    it "instantiates a type" do
      allow(@builder).to receive(:type_klass).and_return @mocked_type
      expect(@mocked_type).to receive(:new).with(
        args: {},
        child_types: {},
        ctx: {},
        root: true
      )
      type = @builder.type
    end
  end

  describe "#add_child_builder" do
    before :each do
      allow(@builder).to receive(:type_klass).and_return @mocked_type
      @field_definition = instance_double RailsQL::Field::FieldDefinition
      allow(@field_definition).to receive(:type).and_return "mocked_type"
      allow(@field_definition).to receive(:child_ctx).and_return({})
      allow(@mocked_type).to receive(:field_definitions).and_return(
        'child_type' => @field_definition
      )
    end

    context "when association field exists" do
      it "intantiates the child builder and adds to builder#child_builders" do
        child_builder = @builder.add_child_builder "child_type"

        expect(@builder.child_builders['child_type']).to eq child_builder
        expect(child_builder.class).to eq RailsQL::Type::Builder
        expect(child_builder.type_klass).to eq MockedType
        expect(child_builder.instance_variable_get("@root")).to eq false
        expect(child_builder.instance_variable_get("@ctx")).to eq({})
      end

      it "merges child_ctx with ctx and passes down to children" do
        expect(@field_definition).to receive(:child_ctx).and_return(
          mega_lasers: :very_yes
        )

        child_builder = @builder.add_child_builder "child_type"
        ctx = child_builder.instance_variable_get(:@ctx)

        expect(ctx[:mega_lasers]).to eq :very_yes
      end

      it "is idempotent" do
        child_builder = @builder.add_child_builder "child_type"

        expect(@builder.add_child_builder('child_type')).to eq child_builder
      end
    end

    context "when association field does not exist" do
      it "raises invalid field error" do
        expect{@builder.add_child_builder 'invalid_type'}.to raise_error
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
