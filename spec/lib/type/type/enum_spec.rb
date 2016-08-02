describe RailsQL::Type do
  let(:type_klass) {Class.new described_class}

  describe ".type_definition.enum_values" do
    context "when enum_values is set" do
      it "sets the enum values" do
        values = [:monkeys, :potatoes]
        type_klass.enum_values :monkeys, :potatoes

        results = type_klass.type_definition.enum_values

        expect(results).to eq(
          monkeys: OpenStruct.new(
            is_deprecated: false,
            deprecation_reason: nil,
            name: :monkeys
          ),
          potatoes: OpenStruct.new(
            is_deprecated: false,
            deprecation_reason: nil,
            name: :potatoes
          ),
        )
      end
    end

    context "when enum_values is not set" do
      context "without args" do
        it "returns an empty array" do
          expect(type_klass.type_definition.enum_values).to eq({})
        end
      end
    end
  end

  describe "#as_json" do
    context "when kind is set to :ENUM" do
      it "returns the model" do
        type_klass.kind :ENUM
        type = type_klass.new
        allow(type).to receive(:model).and_return "mc hammer"

        expect(type.as_json).to eq "mc hammer"
      end
    end
  end

end
