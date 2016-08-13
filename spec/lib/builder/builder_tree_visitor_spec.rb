require "spec_helper"

describe RailsQL::Builder::BuilderTreeVisitor do

  describe "#tree_like_fold" do
    def new_node
      RailsQL::Builder::Node.new(
        name: "initial_state"
      )
    end

    it "reduces through reducers' #visit_node and #end_visit_node methods" do
      node = new_node
      reducer_klasses = []
      reducer_klasses << Class.new do
        def visit_node(
          node:,
          parent_nodes:
        )
          node.name = node.name + " | visit_r1"
          node
        end

        def end_visit_node(
          node:,
          parent_nodes:
        )
          node.name = node.name + " | end_visit_r1"
          node
        end

      end

      reducer_klasses << Class.new do
        def visit_node(
          node:,
          parent_nodes:
        )
          node.name = node.name + " | visit_r2"
          node
        end

        def end_visit_node(
          node:,
          parent_nodes:
        )
          node.name = node.name + " | end_visit_r2"
          node
        end

      end

      reducers = reducer_klasses.map(&:new)
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
      reducer_klasses = []
      reducer_klasses << Class.new do
        def visit_node(
          node:,
          parent_nodes:
        )
          node.name = node.name + " | visit_r1"
          node
        end

      end

      reducers = reducer_klasses.map(&:new)
      result = described_class.new(reducers: reducers).tree_like_fold(
        node: node
      )

      expect(result.name).to eq <<-NAME.gsub(/[\n ]+/, " ").strip
        initial_state |
        visit_r1
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
  end

end
