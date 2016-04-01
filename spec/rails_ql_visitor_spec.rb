require "spec_helper"

describe RailsQLVisitor do
  let :graph_ql {File.read("./resources/queries/hero_friends.graphql")}
  let :ast {GraphQL::Parser.parse graph_ql}

  it "calls the given block on each node" do
  end
end