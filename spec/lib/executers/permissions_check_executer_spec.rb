require "spec_helper"

describe RailsQL::Executers::PermissionsCheckExecuter do
  let(:root) {instance_double RailsQL::Type}

  def field_with_no_children_and_no_args(name:)
    f = instance_double RailsQL::Type
    allow(f).to receive(:field_name).and_return name
    allow(f).to receive(:query_tree_children).and_return []
    allow(f).to receive_message_chain(
      :args_type,
      :query_tree_children
    ).and_return []
    f
  end

  describe "#unauthorized_fields_and_args_for" do
    context "when there are no unauthorized fields" do
      it "can be executed" do
        field_1 = field_with_no_children_and_no_args(name: "cow")
        field_2 = field_with_no_children_and_no_args(name: "horse")
        allow(root).to receive(:query_tree_children).and_return(
          [field_1, field_2]
        )

        allow(root).to receive(:can?).with(:query, "cow").and_return true
        allow(root).to receive(:can?).with(:query, "horse").and_return true

        executer = described_class.new(root: root,
          operation_type: :query
        ).execute!

        actual = executer.unauthorized_fields_and_args
        expect(actual).to eq({})
      end
    end
  end
end
