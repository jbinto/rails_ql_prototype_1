require "spec_helper"

describe RailsQL::Field::FieldCollection do
  let(:type) {instance_double RailsQL::Type}

  let(:field_1) {instance_double RailsQL::Field::Field}
  let(:field_2) {instance_double RailsQL::Field::Field}
  let(:arg_type_1) {instance_double RailsQL::Field::Field}
  let(:arg_type_2) {instance_double RailsQL::Field::Field}

  let(:empty_collection) {described_class.new}
  let(:field_collection) {described_class.new}
  let(:args_collection) {described_class.new}

  describe "#unauthorized_fields_for" do
    context "when there is an unauthorized arg" do
      it <<-END_IT.strip_heredoc.gsub("\n", "") do
        returns a hash containing the unauthorized args in the form
        {field_name => "__args" => {arg_name => true}}}
      END_IT
        field_collection["cow"] = field_1
        args_collection["moo"] = arg_type_1
        args_collection["restricted_moo"] = arg_type_2

        # First call of #unauthorized_fields_and_args_for (for the field collection)
        allow(field_1).to receive(:can?).with(:query).and_return true

        # Since `field_1` can be queried, it will try child fields and arguments.
        # Do not try to simultate nested fields here, use empty_collection.
        allow(field_1).to receive(:child_field_collection).and_return empty_collection
        allow(field_1).to receive_message_chain(
          :args_type,
          :child_field_collection,
        ).and_return args_collection

        # Second call of #unauthorized_fields_and_args_for (for the argument collection)
        allow(arg_type_1).to receive(:can?).with(:query).and_return true

        # Since `arg_type_1` can be queried, it will now try child fields and arguments.
        # Do not try to simultate nested arguments here, use empty_collection.
        allow(arg_type_1).to receive(:child_field_collection).and_return empty_collection
        allow(arg_type_1).to receive_message_chain(
          :args_type,
          :child_field_collection
        ).and_return empty_collection

        # We can skip the child fields and arguments setup for `arg_type_2`
        # since it short circuits when it finds the field can't be queried.
        allow(arg_type_2).to receive(:can?).with(:query).and_return false

        expect(field_collection.unauthorized_fields_and_args_for(:query)).to eq(
          "cow" => {
            "__args" => {
              "restricted_moo" => true
            }
          }
        )
      end
    end

    context "when there are unauthorized fields" do
      it "returns a hash in the form {field_name => true}" do
        field_collection["cow"] = field_1
        field_collection["horse"] = field_2

        # First (only) call of #unauthorized_fields_and_args_for for the field collection
        allow(field_1).to receive(:can?).with(:query).and_return false
        allow(field_2).to receive(:can?).with(:query).and_return true

        # Simulate no child fields or arguments for field_2
        allow(field_2).to receive(:child_field_collection).and_return empty_collection
        allow(field_2).to receive_message_chain(
          :args_type,
          :child_field_collection
        ).and_return empty_collection


        expect(field_collection.unauthorized_fields_and_args_for :query).to eq(
          "cow" => true
        )
      end
    end

    context "when there are nested unauthorized fields" do
      it "returns a nested hash" do
        allow(type).to receive(:fields).and_return stuff: field

        allow(field).to receive(:can?).with(:query).and_return true
        allow(field).to(
          receive_message_chain(:types, :first, :unauthorized_query_fields)
            .and_return(things: true)
        )

        expect(type.unauthorized_query_fields).to eq(
          "stuff" => {"things" => true}
        )
      end
    end
  end

  context "when there are no unauthorized fields" do
    it "returns an empty hash" do
      field_collection["cow"] = field_1
      field_collection["horse"] = field_2

      allow(field_1).to receive(:can?).with(:query).and_return true
      allow(field_2).to receive(:can?).with(:query).and_return true

      # Simulate no child fields or arguments for field_1 and field_2
      [field_1, field_2].each do |f|
        allow(f).to receive(:child_field_collection).and_return empty_collection
        allow(f).to receive_message_chain(
          :args_type,
          :child_field_collection
        ).and_return empty_collection
      end

      expect(field_collection.unauthorized_fields_and_args_for :query).to eq({})
    end
  end

end
