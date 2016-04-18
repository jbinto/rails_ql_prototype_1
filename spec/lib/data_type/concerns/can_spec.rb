require "spec_helper"

describe RailsQL::DataType::Can do
  let(:data_type_klass) {
    klass = Class.new RailsQL::DataType::Base
    klass.field :example_field, data_type: class_double(RailsQL::DataType::Base)
    klass.has_one :child_data_type, data_type: klass
    klass
  }

  describe ".can" do
    context "when :read" do
      context "with :when option" do
        it "calls field_definition#add_read_permission with :when option" do
          permission = ->{true}
          field_definition = data_type_klass.field_definitions[:example_field]

          expect(field_definition).to(
            receive(:add_read_permission).with permission
          )

          data_type_klass.can(:read,
            fields: [:example_field],
            when: permission
          )
        end
      end

      context "without :when option" do
        it "calls field_definition#add_read_permission with `->{true}`" do
          field_definition = data_type_klass.field_definitions[:example_field]

          expect(field_definition).to receive(:add_read_permission) do |lambda|
            expect(lambda.call).to eq true
          end

          data_type_klass.can :read, fields: [:example_field]
        end
      end
    end
  end

  describe "included" do
    it "adds after_resolve :authorize_query, if: :root? callback" do
      dummy_klass = Class.new
      expect(dummy_klass).to receive(:after_resolve).with(
        :authorize_query!, if: :root?
      )

      dummy_klass.include described_class
    end
  end

  describe "instance methods" do
    let(:data_type) {data_type_klass.new(field: {})}
    let(:field) {instance_double RailsQL::DataType::Field}

    describe "#unauthorized_query_fields" do
      context "when there are unauthorized fields" do
        it "returns a hash in the form {field_name => true}" do
          field_2 = instance_double RailsQL::DataType::Field
          allow(data_type).to receive(:fields).and_return(
            stuff: field,
            other_stuff: field_2
          )

          allow(field).to receive(:has_read_permission?).and_return false
          allow(field_2).to receive(:has_read_permission?).and_return true
          data_type.fields.each do |k, field|
            allow(field).to(
              receive_message_chain(:data_types, :first, :unauthorized_query_fields)
                .and_return HashWithIndifferentAccess.new
            )
          end

          unauthorized_query_fields = data_type.unauthorized_query_fields

          expect(unauthorized_query_fields).to eq("stuff" => true)
        end
      end

      context "when there are nested unauthorized fields" do
        it "returns a nested hash" do
          allow(data_type).to receive(:fields).and_return stuff: field

          allow(field).to receive(:has_read_permission?).and_return true
          allow(field).to(
            receive_message_chain(:data_types, :first, :unauthorized_query_fields)
              .and_return(things: true)
          )

          expect(data_type.unauthorized_query_fields).to eq(
            "stuff" => {"things" => true}
          )
        end
      end

    end

    describe "#authorize_query!" do
      context "when unauthorized_query_fields is not empty" do
        it "raises UnauthorizedQuery error" do
          allow(data_type).to receive(:unauthorized_query_fields).and_return(
            example_field: true
          )

          expect{data_type.authorize_query!}.to raise_error
        end
      end

      context "when unauthorized_query_fields is empty" do
        it "does not raise an error" do
          allow(data_type).to receive(:unauthorized_query_fields).and_return(
            HashWithIndifferentAccess.new
          )

          expect{data_type.authorize_query!}.not_to raise_error
        end
      end
    end

    describe "#authorize_mutation!" do
      pending "mutations"
      skip
    end
  end

end


