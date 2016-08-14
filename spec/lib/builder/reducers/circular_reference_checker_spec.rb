require "spec_helper"

describe RailsQL::Builder::Reducers::CircularReferenceChecker do

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

    it "does not throw an error if the fragment does not reference itself" do
      expect{
        described_class.new.visit_node(
          node: fragment_node,
          parent_nodes: [new_node, new_node, new_node]
        )
      }.not_to raise_error
    end

    it "throws an error if the fragment is being referenced inside of itself" do
      expect{
        described_class.new.visit_node(
          node: fragment_node,
          parent_nodes: [new_node, fragment_node, new_node]
        )
      }.to raise_error RailsQL::InvalidFragment
    end

  end

end
