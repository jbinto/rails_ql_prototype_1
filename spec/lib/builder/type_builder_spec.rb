require "spec_helper"

describe RailsQL::Builder::TypeBuilder do
  before :each do
    pending "The implementations of these tests are all out of date."
    fail
    stub_const "MockedType", Class.new(RailsQL::Type)
    @mocked_type = class_double("MockedType")
    @builder = RailsQL::Type::Builder.new(
      type_klass: "mocked_type",
      ctx: {},
      root: true
    )
  end

  describe "#build_type!" do
    it "instantiates the type_kind with args and fields" do
      pending "this test is totally out of date"
      fail
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

  describe "#add_child_builder!" do
    it "wraps child_type_builders#create_and_add_builder!" do
    end

    it "annotates child_type_builders#create_and_add_builder! errors" do
    end
  end

  describe "#add_arg!" do
    it "wraps arg_type_builders#create_and_add_builder!" do
    end

    it "annotates arg_type_builders#create_and_add_builder! errors" do
    end
  end

  describe "#resolve_variables!" do
    pending "dev time for variables"
    fail
    # context "when variable_type_name exists as a type" do
    #   it "adds argument name, variable_name, and variable_type to vars" do
    #     CowType = Class.new RailsQL::Type
    #     @builder.add_variable(
    #       argument_name: "hero",
    #       variable_name: "cow",
    #       variable_type_name: "CowType"
    #     )
    #
    #     expect(@builder.unresolved_variables['hero']).to eq "cow"
    #   end
    # end
    #
    # context "when variable_type_name does not exist as a type" do
    #   it "raises an error" do
    #     expect{@builder.add_variable(
    #       argument_name: "hero",
    #       variable_name: "cow",
    #       variable_type_name: "BogusType"
    #     )}.to raise_error
    #   end
    # end

  end

  describe "#resolve_fragments!" do
    pending "dev time for fragments"
    fail
  end


end
