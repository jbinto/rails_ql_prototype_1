require "spec_helper"

describe RailsQL::Executers::PermissionsCheckExecuter do
  let(:root) {instance_double RailsQL::Type, to_s: "RootTypeDouble"}

  def field_with_no_children_and_no_args(name:)
    f = instance_double RailsQL::Type, to_s: "FieldWithNoArgsTypeDouble_#{name}"
    allow(f).to receive(:field_name).and_return name
    allow(f).to receive(:query_tree_children).and_return []
    allow(f).to receive_message_chain(
      :args_type,
      :query_tree_children
    ).and_return []
    f
  end

  def field_with_args(name:, args_can_input:)
    f = instance_double RailsQL::Type, to_s: "FieldTypeDouble_#{name}"
    expect(f).to receive(:field_name).and_return name
    expect(f).to receive(:query_tree_children).and_return []

    args = []
    args_can_input.each do |name, can_input|
      arg = instance_double RailsQL::Type, to_s: "ArgsTypeDouble_#{name}"
      expect(arg).to receive(:field_name).and_return name

      # Set the parent field's can?
      expect(f).to receive_message_chain(:args_type, :can?).with(:input, name)
        .and_return can_input

      # Nothing nested inside args
      allow(arg).to receive(:query_tree_children).and_return []
      allow(arg).to receive_message_chain(
        :args_type,
        :query_type_children
      ).and_return []

      args << arg
    end

    allow(f).to receive_message_chain(
      :args_type,
      :query_tree_children
    ).and_return(args)

    return f
  end

  def test_executer(root:, expected:, operation_type: :query)
    executer = described_class.new(
      root: root,
      operation_type: operation_type
    ).execute!
    expect(executer.unauthorized_fields_and_args).to eq expected
  end


  describe "#unauthorized_fields_and_args_for" do
    context "when there is an unauthorized arg" do
      it %|returns a hash {field_name => "__args" => {arg_name => true}}| do
        field = field_with_args({
          name: "cow",
          args_can_input: {
            "moo" => true,
            "restricted_moo" => false
          }
        })
        allow(root).to receive(:query_tree_children).and_return [field]
        allow(root).to receive(:can?).with(:query, "cow").and_return true

        test_executer(
          root: root,
          expected: {
            "cow" => {
              "__args" => {
                "restricted_moo" => true
              }
            }
          }
        )
      end
    end

    context "when there are unauthorized fields" do
      it "returns a hash in the form {field_name => true}" do
        field_1 = field_with_no_children_and_no_args(name: "cow")
        field_2 = field_with_no_children_and_no_args(name: "horse")
        allow(root).to receive(:query_tree_children).and_return(
          [field_1, field_2]
        )

        allow(root).to receive(:can?).with(:query, "cow").and_return false
        allow(root).to receive(:can?).with(:query, "horse").and_return true

        test_executer(
          root: root,
          expected: {"cow" => true}
        )
      end
    end

    context "when there are no unauthorized fields" do
      it "returns an empty hash" do
        field_1 = field_with_no_children_and_no_args(name: "cow")
        field_2 = field_with_no_children_and_no_args(name: "horse")
        allow(root).to receive(:query_tree_children).and_return(
          [field_1, field_2]
        )

        allow(root).to receive(:can?).with(:query, "cow").and_return true
        allow(root).to receive(:can?).with(:query, "horse").and_return true

        test_executer(
          root: root,
          expected: {}
        )
      end
    end
  end
end
