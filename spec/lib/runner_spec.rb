require "spec_helper"

describe RailsQL::Runner do
  before :each do
    class_double(RailsQL::DataType::Builder).as_stubbed_const
    class_double(RailsQL::Visitor).as_stubbed_const
    class_double(GraphQL::Parser).as_stubbed_const
    schema = class_double RailsQL::DataType::Base

    @builder = instance_double RailsQL::DataType::Builder
    @visitor = instance_double RailsQL::Visitor
    @root = instance_double RailsQL::DataType::Base
    allow(RailsQL::Visitor).to receive(:new).and_return @visitor
    allow(RailsQL::DataType::Builder).to receive(:new).and_return @builder
    allow(GraphQL::Parser).to receive(:parse).and_return :fake_ast
    allow(@visitor).to receive :accept
    allow(@builder).to receive(:data_type).and_return @root
    allow(@root).to receive :build_query!
    allow(@root).to receive :resolve_child_data_types!

    @runner = RailsQL::Runner.new schema
  end

  context "when query option is not nil" do
    it "instantiates the root builder" do
      expect(RailsQL::DataType::Builder).to receive(:new).and_return @builder
      @runner.execute! query: "hero {}"
    end

    it "parses the graphQL query" do
      expect(GraphQL::Parser).to receive(:parse).and_return :fake_ast
      @runner.execute! query: "hero {}"
    end

    it "calls the visitor with the parsed AST" do
      expect(RailsQL::Visitor).to receive(:new).and_return @visitor
      @runner.execute! query: "hero {}"
    end

    it "returns the root data_type" do
      expect(@builder).to receive(:data_type).and_return @root
      @runner.execute! query: "hero {}"
    end

    it "calls root data_type#build_query!" do
      expect(@root).to receive :build_query!
      @runner.execute! query: "hero {}"
    end

    it "calls root data_type#resolve_child_data_types!" do
      expect(@root).to receive :resolve_child_data_types!
      @runner.execute! query: "hero {}"
    end
  end

  context "when query option is nil" do
    it "raises error" do
      expect{@runner.execute!(query: nil)}.to raise_error
    end
  end
end
