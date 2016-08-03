require "spec_helper"

describe RailsQL::Type do
  let(:type_klass) {Class.new described_class}

  describe "#unauthorized_fields_and_args_for" do
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

  describe "#model=" do
    it "parses the value and stores it in #model" do
      pending "J.E.S.S.E."
      fail
    end
  end

  describe "#build_query!" do
    context "when it has no fields" do
      it "returns the initial query" do
        allow(type_klass).to receive(:get_initial_query).and_return(
          ->{:best_query_ever}
        )
        expect(type_klass.new.build_query!).to eq :best_query_ever
      end
    end

    context "when it has fields" do
      it "calls Field#appended_parent_query and saves results to query" do
        field = instance_double RailsQL::Field::Field
        type = type_klass.new
        allow(type).to receive(:fields).and_return(fake_field: field)
        child_type = instance_double described_class
        allow(field).to receive(:prototype_type).and_return(
          child_type
        )
        allow(child_type).to receive :build_query!
        allow(type_klass).to receive(:get_initial_query).and_return double

        expect(field).to receive(:appended_parent_query).and_return :lions
        type.build_query!
        expect(type.query).to eq :lions
      end

      it "reduces over multiple fields via Field#appended_parent_query" do
        fields = {
          fake_field_1: instance_double(RailsQL::Field::Field),
          fake_field_2: instance_double(RailsQL::Field::Field)
        }
        allow(type_klass).to receive(:get_initial_query).and_return(
          -> {"the cow says"}
        )
        type = type_klass.new
        allow(type).to receive(:fields).and_return fields

        fields.each do |k, field|
          allow(field).to(
            receive_message_chain(:prototype_type, :build_query!).and_return(
              double
            )
          )
          expect(field).to receive(:appended_parent_query) do
            type.query + " moo"
          end.once
        end
        expect(type.build_query!).to eq "the cow says moo moo"
      end
    end
  end

  describe "#resolve_child_types!" do
    before :each do
      @type = type_klass.new
      @field = instance_double RailsQL::Field::Field
      allow(@type).to receive(:fields).and_return(fake_field: @field)
      allow(@field).to receive :parent_type=
      allow(@field).to receive :resolve_models_and_dup_type!
      allow(@field).to receive(:types).and_return []
    end

    it "assigns self as the parent_type to each field" do
      expect(@field).to receive(:parent_type=).with @type

      @type.resolve_child_types!
    end

    it "calls Field#resolve_models_and_dup_type! for each field" do
      expect(@field).to receive :resolve_models_and_dup_type!
      @type.resolve_child_types!
    end

    it "calls resolve_child_types! on child_types" do
      field_type = instance_double described_class
      allow(@field).to receive(:types).and_return [field_type]

      expect(field_type).to receive :resolve_child_types!


      @type.resolve_child_types!
    end

    it "runs resolve callbacks" do
      expect do |b|
        type_klass.before_resolve &b
        @type.resolve_child_types!
      end.to yield_control
    end

  end

  describe "#as_json" do
    context "when kind is defaulted to :OBJECT" do
      it "reduces over #as_json on fields" do
        field = instance_double RailsQL::Field::Field
        allow(field).to receive(:singular?).and_return true
        type = type_klass.new
        allow(type).to receive(:fields).and_return(
          fake_field_1: field,
          fake_field_2: field
        )
        allow(field).to receive_message_chain(:types, :as_json).and_return(
          ["hello" => "world"]
        )

        expect(type.as_json).to eq(
          "fake_field_1" => {"hello" => "world"},
          "fake_field_2" => {"hello" => "world"}
        )
      end
    end

  end
end
