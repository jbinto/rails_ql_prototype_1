require "spec_helper"

describe RailsQL::Type::Can do
  let(:type_klass) {
    klass = Class.new RailsQL::Type::Type
    klass.field :example_field, type: class_double(RailsQL::Type::Type)
    klass.has_one :child_type, type: klass
    klass
  }

  describe ".can" do
    context "when :read" do
      context "with :when option" do
        context "when the field definition for that field exists" do
          it "calls field_definition#add_read_permission with :when option" do
            permission = ->{true}
            field_definition = type_klass.field_definitions[:example_field]

            expect(field_definition).to(
              receive(:add_read_permission).with permission
            )

            type_klass.can(:read,
              fields: [:example_field],
              when: permission
            )
          end
        end
      end

      context "when the field definition for that field does not exist" do
        it "raises error" do
          expect{
            type_klass.can(:read,
              fields: [:fake_field]
            )
          }.to raise_error
        end
      end

      context "without :when option" do
        it "calls field_definition#add_read_permission with `->{true}`" do
          field_definition = type_klass.field_definitions[:example_field]

          expect(field_definition).to receive(:add_read_permission) do |lambda|
            expect(lambda.call).to eq true
          end

          type_klass.can :read, fields: [:example_field]
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
    let(:type) {type_klass.new(field: {})}
    let(:field) {instance_double RailsQL::Field::Field}

    describe "#unauthorized_query_fields" do
      context "when there are unauthorized fields" do
        it "returns a hash in the form {field_name => true}" do
          field_2 = instance_double RailsQL::Field::Field
          allow(type).to receive(:fields).and_return(
            stuff: field,
            other_stuff: field_2
          )

          allow(field).to receive(:has_read_permission?).and_return false
          allow(field_2).to receive(:has_read_permission?).and_return true
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

          allow(field).to receive(:has_read_permission?).and_return true
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

    describe "#authorize_query!" do
      context "when unauthorized_query_fields is not empty" do
        it "raises UnauthorizedQuery error" do
          allow(type).to receive(:unauthorized_query_fields).and_return(
            example_field: true
          )

          expect{type.authorize_query!}.to raise_error
        end
      end

      context "when unauthorized_query_fields is empty" do
        it "does not raise an error" do
          allow(type).to receive(:unauthorized_query_fields).and_return(
            HashWithIndifferentAccess.new
          )

          expect{type.authorize_query!}.not_to raise_error
        end
      end
    end

    describe "#authorize_mutation!" do
      pending "mutations"
      skip
    end
  end

end


