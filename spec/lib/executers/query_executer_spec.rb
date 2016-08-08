require "spec_helper"



describe RailsQL::Executers::QueryExecuter do
  def run_query_executer_test(root:, operation_type: :query)
    described_class.new(
      root: root,
      operation_type: operation_type
    ).execute!
  end

  describe '#execute!' do
    context "with child nodes" do
      def make_node(name)
        instance_double RailsQL::Type, name
      end

      def node_with_no_children(name: "NodeWithNoChildren")
        node = make_node name
        expect(node).to receive(:query_tree_children).and_return([])
        return node
      end

      def node_with_children(children, name: "NodeWithChildren")
        node = make_node name
        expect(node).to receive(:query_tree_children).and_return(children)
        return node
      end

      def expect_initial_query(on:, with:)
        expect(on).to receive(:initial_query).and_return with
        expect(on).to receive(:query=).with(with)
      end

      it "sets initial query on root" do
        # e.g. { root }
        root = node_with_no_children name: "Root"

        expect(root).to receive(:initial_query).and_return nil
        expect(root).to receive(:query=).with(nil)

        run_query_executer_test(root: root)
      end

      it "sets initial query on children one-level deep" do
        # e.g. { root { field_1 }}
        field_1 = node_with_no_children name: "Field_1"
        root = node_with_children([field_1])

        expect_initial_query(on: root, with: nil)
        expect_initial_query(on: field_1, with: "Moo.all")

        run_query_executer_test(root: root)
      end

      it "sets initial query on children one-level deep" do
        # e.g. { root { field_1 { field_1_a }}}
        field_1_a = node_with_no_children name: "Field_1_a"
        field_1 = node_with_children [field_1_a], name: "Field_1"
        root = node_with_children [field_1], name: "Root"

        expect_initial_query(on: root, with: nil)
        expect_initial_query(on: field_1, with: "Field_1.all")
        expect_initial_query(on: field_1_a, with: "Field_1_a.all")

        run_query_executer_test(root: root)
      end
    end
  end

end
