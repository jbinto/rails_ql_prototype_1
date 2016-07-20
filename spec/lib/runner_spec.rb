require "spec_helper"

describe RailsQL::Runner do
  before :each do
    @schema = Class.new RailsQL::Type
    @mutation = Class.new RailsQL::Type

    @visitor = instance_double RailsQL::Visitor
    allow(RailsQL::Visitor).to receive(:new).and_return @visitor
    allow(GraphQL::Parser).to receive(:parse).and_return :fake_ast
    allow(@visitor).to receive :accept
    @schema_builder = double
    @schema_type = double
    allow(@schema_builder).to receive(:type).and_return @schema_type
    allow(@schema_type).to receive(:build_query!)
    allow(@schema_type).to receive(:resolve_child_types!)
    allow(@visitor).to receive(:root_builders).and_return [@schema_builder]

    @runner = RailsQL::Runner.new query_root: @schema, mutation_root: @mutation
  end

  context "when query option is not nil" do
    it "instantiates a query root builder and a mutation root builder" do
      expect(RailsQL::Type::Builder).to receive(:new).twice.and_call_original
      @runner.execute! query: "hero {}"
    end

    it "parses the graphQL query" do
      expect(GraphQL::Parser).to receive(:parse).and_return :fake_ast
      @runner.execute! query: "hero {}"
    end

    it "calls the visitor with the parsed AST" do
      expect(@visitor).to receive(:accept).with :fake_ast
      @runner.execute! query: "hero {}"
    end

    it "returns the appropriate root type" do
      root = @runner.execute! query: "hero {}"
      expect(root).to eq @schema_type
    end

    it "raises error with multiple operations" do
      allow(@visitor).to receive(:root_builders).and_return [
        @schema_builder, @schema_builder
      ]
      expect{@runner.execute! query: "hero {}"}.to raise_error
    end
  end

  context "when query option is nil" do
    it "raises error" do
      expect{@runner.execute!(query: nil)}.to raise_error
    end
  end

  context "when variables are included in the query" do
    
  end
end
