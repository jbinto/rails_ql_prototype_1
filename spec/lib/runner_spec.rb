require "spec_helper"

describe RailsQL::Runner do
  before :each do
    @schema = Class.new RailsQL::DataType::Base
    @mutation = Class.new RailsQL::DataType::Base

    @visitor = instance_double RailsQL::Visitor
    allow(RailsQL::Visitor).to receive(:new).and_return @visitor
    allow(GraphQL::Parser).to receive(:parse).and_return :fake_ast
    allow(@visitor).to receive :accept

    @runner = RailsQL::Runner.new query_root: @schema, mutation_root: @mutation
  end

  context "when query option is not nil" do
    it "instantiates a query root builder and a mutation root builder" do
      expect(RailsQL::DataType::Builder).to receive(:new).twice.and_call_original
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

    it "returns the query root data_type and mutation root data_type" do
      result = @runner.execute! query: "hero {}"
      expect(result.first.class).to eq @schema
      expect(result.last.class).to eq @mutation
    end
  end

  context "when query option is nil" do
    it "raises error" do
      expect{@runner.execute!(query: nil)}.to raise_error
    end
  end
end
