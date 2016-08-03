require "spec_helper"

describe RailsQL::Field::FieldCollection do

  let(:type) {instance_double RailsQL::Type}
  let(:field) {instance_double RailsQL::Field::Field}

  describe "#unauthorized_fields_for" do
    context "when there are unauthorized args" do
      it <<~END_IT.gsub("\n", "") do
        returns a hash in the form
        {field_name => \"__args\" => {arg_name => true}}}
      END_IT
        pending "Jesse  🕵🕸=>📝💾=>🏆🏆🏆🏌"
        fail
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
