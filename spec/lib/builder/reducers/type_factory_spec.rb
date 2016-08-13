require "spec_helper"

describe RailsQL::Builder::Reducers::TypeFactory do
  def new_node(
      name: "Moo #{Random.rand(100)}",
      root: false
      # fragment: false,
      # directive: false,
      # field_or_input_field: false,
    )
    node = RailsQL::Builder::Node.new(
      annotation: instance_double(RailsQL::Builder::Annotation,
        name,     # debug info for Rspec Instance double classname
        name: name,
        root?: root
        # fragment?: fragment,
        # directive?: directive,
        # field_or_input_field?: field_or_input_field
      )
    )
    node
  end

  def instance
    described_class.new
  end

  describe "#initialize" do
    it "constructs without exploding" do
      instance
    end
  end

  describe "#visit_node" do
    it "raises if any params are nil" do
      expect{instance.visit_node(node: 0, parent_nodes: nil)}.to raise_error
      expect{instance.visit_node(node: nil, parent_nodes: 0)}.to raise_error
    end

    it "returns node untouched if it is a root node" do
      node = new_node root: true
      new_node = instance.visit_node(node: node, parent_nodes: [])

      # XXX: if we do shallow_clone, this will need to change
      expect(node).to eq(new_node)
    end

    describe "instantiates a type" do
      it "sets node.type="
      it ":ctx with merged parent/child context"
      it ":root with node root"
      it ":field_definition with node root"
      it ":aliased_as with node.aliased_as or name"
    end

    it "sets type.model using XXX???"
  end

  describe "#end_visit_node" do
    context "when the node is an input" do
      it "sets node.list_of_resolved_types="
    end

    context "when the node is a list" do
      # good case for rspec shared examples? same test, different input
      it "sets node.list_of_resolved_types="
    end

    context "when the node is a modifier_type" do
      it "sets node.modified_type="
    end

    context "when the node is not a modifier, directive, or union" do
      it "sets node.field_types="
    end

    context "when the node is a directive" do
      it "is not implemented"
    end

    context "when the node is a union" do
      it "is not implemented"
    end
  end
end
