require "spec_helper"

describe RailsQL::Builder::Reducers::TypeKlassResolver do

  def new_node(root: false, fragment: false)
    root_node = instance_double(RailsQL::Builder::Node,
      root?: root,
      fragment?: fragment
    )
  end

  describe "#visit_node" do
    it "does nothing to root nodes" do
      root_node = new_node root: true
      result = described_class.new.visit_node(
        node: root_node,
        parent_nodes: []
      )

      expect(result).to eq root_node
    end

    it "does nothing to fragments" do
      fragment_node = new_node fragment: true
      result = described_class.new.visit_node(
        node: fragment_node,
        parent_nodes: []
      )

      expect(result).to eq fragment_node
    end

    it "sets `node.field_definition` for a field" do

    end

    it "sets `node.type_klass` for the modified type of a list" do

    end

    it "sets `node.type_klass` for the modified type of a non null" do

    end

    it "sets `node.type_klass` for a directive" do
      pending
      fail
    end

    it "sets `node.field_definition` for a field inside a directive" do
      pending
      fail
    end

  end

end
