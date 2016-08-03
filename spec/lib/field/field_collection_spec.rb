require "spec_helper"

describe RailsQL::Field::FieldCollection do

  let(:type) {instance_double RailsQL::Type}
  let(:field) {instance_double RailsQL::Field::Field}
  let(:arg_type) {instance_double RailsQL::Field::Field}

  describe "#unauthorized_fields_for" do
    context "when there is an unauthorized arg" do
      it <<-END_IT.strip_heredoc.gsub("\n", "") do
        returns a hash in the form
        {field_name => \"__args\" => {arg_name => true}}}
      END_IT
        empty_collection = described_class.new

        field_collection = described_class.new
        field_collection["cow"] = field

        args_collection = described_class.new
        args_collection["moo"] = arg_type

        # First call of #unauthorized_fields_and_args_for for the field collection
        allow(field).to receive(:can?).with(:query).and_return true
        allow(field).to receive(:child_field_collection).and_return empty_collection
        allow(field).to receive_message_chain(
          :args_type,
          :child_field_collection,
        ).and_return args_collection

        # Second call of #unauthorized_fields_and_args_for for the argument collection
        allow(arg_type).to receive(:can?).with(:query).and_return false

        expect(field_collection.unauthorized_fields_and_args_for(:query)).to eq(
          "cow" => {
            "__args" => {
              "moo" => true
            }
          }
        )
      end
    end

    context "when there are unauthorized fields" do
      it "returns a hash in the form {field_name => true}" do
        field_2 = instance_double RailsQL::Field::Field
        allow(type).to receive(:fields).and_return(
          stuff: field,
          other_stuff: field_2
        )

        allow(field).to receive(:can?).with(:query).and_return false
        allow(field_2).to receive(:can?).with(:query).and_return true
        type.fields.each do |k, field|
          allow(field).to(
            receive_message_chain(:types, :first, :unauthorized_query_fields)
              .and_return HashWithIndifferentAccess.new
          )
        end

        unauthorized_query_fields = type.unauthorized_query_fields

        expect(unauthorized_query_fields).to eq("stuff" => true)
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
