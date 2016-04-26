require "spec_helper"

describe RailsQL::Visitor do
  let(:root_builder) { instance_double "RailsQL::DataType::Builder" }
  let(:visitor) {RailsQL::Visitor.new(root_builder)}

  def visit_graphql(graphql)
    ast = GraphQL::Parser.parse(graphql)
    visitor.accept ast
  end

  describe "#accept" do
    it "calls builder#add_child_builder for each child field node" do
      expect(root_builder).to receive(:add_child_builder).with 'hero'

      visit_graphql "query { hero }"
    end

    it "calls builder#add_arg for each arg" do
      hero_builder = double
      allow(root_builder).to receive(:add_child_builder).and_return hero_builder
      expect(hero_builder).to receive(:add_arg).with('id', 3)

      visit_graphql "query { hero(id: 3) }"
    end

    it "calls for each subscription" do
      visit_graphql "subscription heroQuery{ hero }"
    end

    it "calls for each mutation" do
      visit_graphql "mutation updateHero{ hero }"
    end

    it "calls for each __type" do
      visit_graphql "__type{ name: \"hero\" }"
    end

  # it "parses queries with fragments into data types" do
  #   visit_graphql "
  #     query { hero { ...heroFriendsFragment } }
  #     fragment heroFriendsFragment on Hero { friends }
  #   "

  #   children = visitor.schema.children

  #   expect(children[:hero].children[:friends].class).to eq HeroType
  # end
  end
end

