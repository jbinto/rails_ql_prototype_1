require "spec_helper"

describe RailsQL::DataType::Union do
  let(:data_type_klass) {Class.new described_class}


  describe ".unions" do
    it "creates field definitions" do
      data_type_klass.unions(
        {name: "sword", data_type: "SwordDataType", model_klass: "Sword"},
        {name: "crossbow", data_type: "CrossbowDataType",
          model_klass: "Crossbow"
        }
      )

      expect(data_type_klass.field_definitions.count).to eq 2
      expect(data_type_klass.field_definitions["sword"].union).to eq true
      expect(data_type_klass.field_definitions["crossbow"].union).to eq true
    end
  end

  describe "#to_json" do
    before :each do
      Sword = Class.new
      Crossbow = Class.new
      SwordDataType = Class.new RailsQL::DataType::Base
      SwordDataType.field :damage, data_type: "Int"
      SwordDataType.can :read, fields: [:damage]
      CrossbowDataType = Class.new RailsQL::DataType::Base
      CrossbowDataType.field :damage, data_type: "Int"
      CrossbowDataType.field :range, data_type: "Int"
      CrossbowDataType.can :read, fields: [:damage, :range]
      data_type_klass.unions(
        {name: "sword", data_type: "SwordDataType", model_klass: "Sword"},
        {name: "crossbow", data_type: "CrossbowDataType",
          model_klass: ->{"Crossbow"}
        }
      )
      data_type_klass.can :read, fields: [:sword, :crossbow]
      @runner = RailsQL::Runner.new data_type_klass
    end

    it "returns the appropriate fields based on the type of the resolved union model" do
      sword = OpenStruct.new(
        damage: 5
      )
      crossbow = OpenStruct.new(
        damage: 6,
        range: 100
      )
      query = "query {
        ... on Sword {
          damage
        }
        ... on Crossbow {
          damage
          range
        }
      }"

      allow_any_instance_of(data_type_klass).to receive(:model).and_return sword
      allow(sword).to receive(:kind_of?).with(Sword).and_return true
      allow(sword).to receive(:kind_of?).with(Crossbow).and_return false
      results = @runner.execute!(query: query).as_json
      expect(results.keys).to eq ["damage"]
      expect(results["damage"]).to eq 5

      allow_any_instance_of(data_type_klass).to receive(:model).and_return(
        crossbow
      )
      allow(crossbow).to receive(:kind_of?).with(Sword).and_return false
      allow(crossbow).to receive(:kind_of?).with(Crossbow).and_return true
      results = @runner.execute!(query: query).as_json
      expect(results.keys).to eq ["damage", "range"]
      expect(results["damage"]).to eq 6
      expect(results["range"]).to eq 100
    end
  end
end
