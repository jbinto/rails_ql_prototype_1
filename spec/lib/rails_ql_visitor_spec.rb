require "spec_helper"

class HeroType
  attr_reader :parent, :children

  def initialize(opts)
    @parent = opts[:parent]
    @children = {}
  end

  def field_definitions
    return {
      "friends" => {
        klass: HeroType
      }
    }
  end
end


class Schema
  attr_reader :parent, :children

  def initialize(opts)
    @parent = opts[:parent]
    @children = {}
  end

  def field_definitions
    return {
      "hero" => {
        klass: HeroType
      }
    }
  end
end

describe RailsQLVisitor do
  let(:visitor) {RailsQLVisitor.new(Schema.new(parent: nil))}

  def visit_graphql(graphql)
    ast = GraphQL::Parser.parse(graphql)
    visitor.accept ast
  end

  it "parses queries into data types" do
    visit_graphql "query { hero { friends } }"

    children = visitor.root.children

    expect(children.count).to eq 1
    expect(children[:hero].class).to eq HeroType
    expect(children[:hero].children[:friends].class).to eq HeroType
  end

  # it "parses queries with fragments into data types" do
  #   visit_graphql "
  #     query { hero { ...heroFriendsFragment } }
  #     fragment heroFriendsFragment on Hero { friends }
  #   "

  #   children = visitor.schema.children

  #   expect(children[:hero].children[:friends].class).to eq HeroType
  # end

  it "raises an error if query types do not match the schema data types" do
    expect{
      visit_graphql("query { invalid_data_type }")
    }.to raise_error(
      "Invalid field invalid_data_type"
    )
  end
end

