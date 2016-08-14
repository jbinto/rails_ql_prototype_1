require "spec_helper"

describe RailsQL::Builder::Reducers::TypeFactory do
  def new_node(
    double_name: "annotation",
    type_klass: nil,
    type: nil,
    field_definition: nil,
    **annotation_attrs
  )
    RailsQL::Builder::Node.new(
      type_klass: type_klass,
      field_definition: field_definition,
      type: type,
      annotation: instance_double(RailsQL::Builder::Annotation,
        double_name,
        annotation_attrs || {}
      )
    )
  end

  let(:reducer) {described_class.new}

  describe "#visit_node" do
    context "invalid states" do

      let(:valid_node) {
        new_node(
          type_klass: class_double(RailsQL::Type),
          root?: false
        )
      }

      let(:valid_parent) {
        new_node(
          type: instance_double(RailsQL::Type,
            ctx: {}
          )
        )
      }

      it "errors if the immediate parent node's ctx is not set" do
        expect{
          reducer.visit_node(
            node: valid_node,
            parent_nodes: [
              new_node(type: instance_double(RailsQL::Type, ctx: nil))
            ]
          )
        }.to raise_error
      end

      it "errors if the node's type_klass is not set" do
        expect{
          reducer.visit_node(
            node: new_node(
              type_klass: nil,
              root?: false
            ),
            parent_nodes: [
              valid_parent
            ]
          )
        }.to raise_error
      end
    end

    context "for a root node" do
      it "returns node untouched" do
        node = new_node root?: true

        result = reducer.visit_node(node: node, parent_nodes: [])

        expect(result.annotation).to eq(node.annotation)
      end
    end

    context "for a non-root node" do
      let(:type_klass) {Class.new(RailsQL::Type)}
      let(:field_definition) {
        instance_double(RailsQL::Field::FieldDefinition,
          child_ctx: {a_thing_from_child_ctx: 5}
        )
      }
      let(:node) {
        new_node(
          double_name: "node double",
          aliased_as: "moo_alias",
          model: "an actual cow",
          type_klass: type_klass,
          field_definition: field_definition,
          root?: false
        )
      }
      let(:parent_node) {
        new_node(
          double_name: "parent node double",
          type: instance_double(RailsQL::Type,
            ctx: {a_thing_from_parent_ctx: 3}
          )
        )
      }
      let(:result) {
        reducer.visit_node(
          node: node,
          parent_nodes: [parent_node]
        )
      }

      it "sets node.type= to a new instance of node.type_klass" do
        expect(result.type.is_a? type_klass).to eq true
      end

      it "sets ctx by merging the parent/child contexts" do
        expect(result.ctx).to eq(
          a_thing_from_child_ctx: 5,
          a_thing_from_parent_ctx: 3
        )
      end

      it "sets type.root to node.root" do
        expect(result.type.root?).to eq false
      end

      it "sets type.field_definition to node.field_definition" do
        expect(result.type.field_definition).to eq field_definition
      end

      it "sets type.aliased_as to node.aliased_as" do
        expect(result.type.aliased_as).to eq "moo_alias"
      end

      it "sets type.model to node.model" do
        expect(result.type.model).to eq "an actual cow"
      end

    end

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
