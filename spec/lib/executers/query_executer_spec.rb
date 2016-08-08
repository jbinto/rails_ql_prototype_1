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
      def root_with_no_children
        root = instance_double RailsQL::Type, "RootTypeDouble"
        expect(root).to receive(:initial_query).and_return nil
        expect(root).to receive(:query=).with(nil)
        expect(root).to receive(:query_tree_children).and_return([])

        return root
      end

      def root_with_children(fields)
        root = instance_double RailsQL::Type, "RootWithChildren"
        expect(root).to receive(:initial_query).and_return nil
        expect(root).to receive(:query=).with(nil)
        expect(root).to receive(:query_tree_children).and_return(fields)

        return root
      end

      it "sets initial query on root" do
        root = root_with_no_children
        run_query_executer_test(root: root)
      end

      it "sets initial query on children one-level deep" do
        field_1 = instance_double RailsQL::Type, "Field"
        root = root_with_children([field_1])

        expect(field_1).to receive(:initial_query).and_return("Foo.all")
        expect(field_1).to receive(:query=).and_return("Foo.all")
        expect(field_1).to receive(:query_tree_children).and_return []

        run_query_executer_test(root: root)
      end
    end
  end

end
