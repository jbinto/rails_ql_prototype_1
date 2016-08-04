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
    # f = instance_double RailsQL::Type, to_s: "FieldWithArgsTypeDouble_#{name}"
    # allow(f).to receive(:field_name).and_return name
    # allow(f).to receive(:query_tree_children).and_return []
    # allow(f).to receive_message_chain(
    #   :args_type,
    #   :query_tree_children
    # ).and_return []
    # f

    f = instance_double(RailsQL::Type,
      to_s: "Field_#{name}",
      field_name: name,
      query_tree_children: []
    )

    anon_input_object = instance_double(RailsQL::Type::AnonymousInputObject,
      to_s: "AnnonomousInputObject_#{name}",
      query_tree_children: []
    )
    allow(f).to receive(:args_type).and_return anon_input_object

    args = []
    args_can_input.each do |name, can_input|
      arg = instance_double RailsQL::Type, to_s: "Arg_#{name}"
      allow(arg).to receive(:field_name).and_return name

      # Allow a can? check on f for the arg `name` on the args_type
      allow(anon_input_object).to receive(
        :can?
      ).with(:input, name).and_return can_input

      # Nothing nested inside args
      allow(arg).to receive(:query_tree_children).and_return []
      allow(arg).to receive_message_chain(
        :args_type,
        :query_tree_children
      ).and_return []

      args << arg
    end

    allow(anon_input_object).to receive(
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
        # cow(moo: true, restricted_moo: false)
        field = field_with_args(
          name: "cow",
          args_can_input: {
            "moo" => true,
            "restricted_moo" => false
          }
        )
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

    context "when there are args and they are all authorized" do
      it "returns an empty hash" do
        pending
        fail
      end
    end
  end
end
