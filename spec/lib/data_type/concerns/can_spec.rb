require "spec_helper"

describe RailsQL::DataType::Can do
  let(:data_type_klass) {
    klass = Class.new RailsQL::DataType::Base
    klass.field :example_field, data_type: RailsQL::DataType::String
    klass.has_one :child_data_type, data_type: klass
    klass
  }

  describe ".can" do
    context "when :read" do
      context "with when option" do
        it "calls field_definition#add_read_permission with when option" do
          permission = ->{context.current_user.owner? model}
          field_definition = data_type_klass.field_definitions[:example_field]

          expect(field_definition).to receive(:add_read_permission).with permission

          data_type_klass.can(:read,
            fields: [:example_field],
            when: permission
          )
        end
      end

      context "without when option" do
        it "calls field_definition#add_read_permission with default lambda" do
          field_definition = data_type_klass.field_definitions[:example_field]

          expect(field_definition).to receive(:add_read_permission).with ->{true}

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
    let(:data_type) { data_type_klass.new fields: {
        example_field: RailsQL::DataType::String.new,
        child_data_type: data_type_klass.new(fields: {
          example_field: RailsQL::DataType::String.new
        })
      }}

    describe "#unauthorized_query_fields" do
      it "returns a subset of fields which cannot be read, including children" do
        field_definition = data_type_klass.field_definitions[:example_field]
        child_field_definition = data_type_klass.field_definitions[
          :child_data_type
        ]
        child_example_field_definition = child_field_definition
          .data_type.field_definitions[:example_field]

        expect(field_definition).to receive(:readable?).and_return false
        expect(child_field_definition).to receive(:readable?).and_return true
        expect(child_example_field_definition).to receive(:readable?).and_return false

        unauthorized_query_fields = data_type.unauthorized_query_fields

        expect(unauthorized_query_fields).to eq([
          "example_field",
          "child_data_type" => ["example_field"]
        ])
      end
    end

    describe "#authorize_query!" do
      context "when unauthorized_query_fields is not empty" do
        it "raises UnauthorizedQuery error" do
          allow(data_type).to receive(:unauthorized_query_fields).and_return(
            # HashWithIndifferentAccess.new
            [:example_field]
          )

          expect{data_type.authorize_query!}.to raise_error
        end
      end

      context "when unauthorized_query_fields is empty" do
        it "returns true" do
          allow(data_type).to receive(:unauthorized_query_fields).and_return(
            # HashWithIndifferentAccess.new
            []
          )

          expect(data_type.authorize_query!).to eq true
        end
      end
    end

    describe "#authorize_mutation!" do
      pending "mutations"
      skip
    end
  end

end


