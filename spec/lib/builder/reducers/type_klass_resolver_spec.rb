require "spec_helper"

describe RailsQL::Builder::Reducers::TypeKlassResolver do

  describe "#visit_node" do
    def new_node
      instance_double(RailsQL::Builder::Node,
        name: "not_moo #{Random.rand(100)}",
        annotation: instance_double(RailsQL::Builder::Annotation),
        fragment?: false
      )
    end

    let(:fragment_node) {
      instance_double(RailsQL::Builder::Node,
        name: "moo",
        annotation: instance_double(RailsQL::Builder::Annotation),
        fragment?: true
      )
    }

    it "does nothing to root nodes" do
      root_node = instance_double(RailsQL::Builder::Node,
        root?: true
      )
      result = described_class.new.visit_node(
        node: root_node,
        parent_nodes: []
      )

      expect(result).to eq root_node
    end

    it "does nothing to fragments" do

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
