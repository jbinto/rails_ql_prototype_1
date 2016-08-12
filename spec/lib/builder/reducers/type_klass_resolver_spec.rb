require "spec_helper"

describe RailsQL::Builder::Reducers::TypeKlassResolver do

  def new_node(
      root: false,
      fragment: false,
      directive: false,
      field_or_input_field: false,
      name: "Moo #{Random.rand(100)}"
    )
    node = RailsQL::Builder::Node.new(
      annotation: instance_double(RailsQL::Builder::Annotation,
        name,     # debug info for Rspec Instance double classname
        name: name,
        root?: root,
        fragment?: fragment,
        directive?: directive,
        field_or_input_field?: field_or_input_field
      )
    )
    node
  end

  describe "#visit_node" do
    it "does nothing to root nodes" do
      root_node = new_node root: true
      result = described_class.new.visit_node(
        node: root_node,
        parent_nodes: []
      )

      expect(result.annotation).to eq root_node.annotation
    end

    it "does nothing to fragments" do
      fragment_node = new_node fragment: true
      result = described_class.new.visit_node(
        node: fragment_node,
        parent_nodes: []
      )

      expect(result.annotation).to eq fragment_node.annotation
    end

    it "sets `node.field_definition` for a field by looking it up in it's parent FieldCollection" do
      node = new_node name: "AwesomeNode", field_or_input_field: true
      parent_node = new_node

      field_definition = instance_double RailsQL::Field::FieldDefinition

      allow(parent_node).to receive_message_chain(
        :child_field_definitions,
        :[]
      ).with("AwesomeNode").and_return field_definition

      result_node = described_class.new.visit_node(
        node: node,
        parent_nodes: [new_node, new_node, parent_node]
      )

      ap node
      expect(result_node).not_to eq node
      expect(result_node.annotation).to eq node.annotation
      expect(result_node.field_definition).to eq field_definition
    end

    it "sets `node.field_definition` for a field and skips directive/fragment parents" do
      node = new_node name: "AwesomeNode", field_or_input_field: true
      parent_node = new_node

      fragment_node_to_skip = new_node fragment: true
      directive_node_to_skip = new_node directive: true

      field_definition = instance_double RailsQL::Field::FieldDefinition

      expect(parent_node).to receive_message_chain(
        :child_field_definitions,
        :[]
      ).with("AwesomeNode").and_return field_definition

      result_node = described_class.new.visit_node(
        node: node,
        parent_nodes: [
          new_node,
          new_node,
          parent_node,
          directive_node_to_skip,
          fragment_node_to_skip
        ]
      )

      expect(result_node.field_definition).to eq field_definition
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
