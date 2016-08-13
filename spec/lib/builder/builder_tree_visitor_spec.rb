require "spec_helper"

describe RailsQL::Builder::BuilderTreeVisitor do

  describe "#tree_like_fold" do
    def new_node
      RailsQL::Builder::Node.new(
        name: "initial_state"
      )
    end

    let(:visit_reducer_klass) {
      Class.new do
        def initialize(name)
          @name = name
        end

        def visit_node(
          node:,
          parent_nodes:
        )
          node.name = node.name + " | visit_#{@name}"
          node
        end
      end
    }

    let(:visit_and_end_visit_reducer_klass) {
      Class.new do
        def initialize(name)
          @name = name
        end

        def visit_node(
          node:,
          parent_nodes:
        )
          node.name = node.name + " | visit_#{@name}"
          node
        end

        def end_visit_node(
          node:,
          parent_nodes:
        )
          node.name = node.name + " | end_visit_#{@name}"
          node
        end
      end
    }

    it "reduces through reducers' #visit_node and #end_visit_node methods" do
      node = new_node
      reducers = (1..2).map do |n|
        visit_and_end_visit_reducer_klass.new "r#{n}"
      end

      result = described_class.new(reducers: reducers).tree_like_fold(
        node: node
      )

      expect(result.name).to eq <<-NAME.gsub(/[\n ]+/, " ").strip
        initial_state |
        visit_r1 |
        visit_r2 |
        end_visit_r2 |
        end_visit_r1
      NAME
    end

    it "skips missing methods on reducers" do
      node = new_node
      reducers = [
        visit_reducer_klass.new("r1"),
        visit_and_end_visit_reducer_klass.new("r2")
      ]

      result = described_class.new(reducers: reducers).tree_like_fold(
        node: node
      )

      expect(result.name).to eq <<-NAME.gsub(/[\n ]+/, " ").strip
        initial_state |
        visit_r1 |
        visit_r2 |
        end_visit_r2
      NAME
    end

    it "returns a clone of the node" do
      node = new_node

      result = described_class.new(reducers: []).tree_like_fold(
        node: node
      )

      expect(result).not_to eq node
      expect(result.annotation).to eq node.annotation
    end

    it "recurses into child nodes" do
      child_node = RailsQL::Builder::Node.new(
        name: "child_node"
      )
      parent_node = RailsQL::Builder::Node.new(
        name: "parent_node",
        child_nodes: [child_node]
      )

      reducers = (1..2).map do |n|
        visit_and_end_visit_reducer_klass.new "r#{n}"
      end

      result = described_class.new(reducers: reducers).tree_like_fold(
        node: parent_node
      )

      expect(result.child_nodes.length).to eq 1
      expect(result.name).to eq(
        <<-NAME.gsub(/[\n ]+/, " ").strip
          parent_node |
          visit_r1 |
          visit_r2 |
          end_visit_r2 |
          end_visit_r1
        NAME
      )
      expect(result.child_nodes.first.name).to eq(
        <<-NAME.gsub(/[\n ]+/, " ").strip
          child_node |
          visit_r1 |
          visit_r2 |
          end_visit_r2 |
          end_visit_r1
        NAME
      )
    end

  end

end
