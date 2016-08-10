require "spec_helper"

describe RailsQL::Union do
  let(:type_klass) {Class.new described_class}


  describe ".unions" do
    it "creates field definitions" do
      type_klass.unions(
        {name: "sword", type: "SwordType", model_klass: "Sword"},
        {name: "crossbow", type: "CrossbowType",
          model_klass: "Crossbow"
        }
      )

      expect(type_klass.field_definitions.count).to eq 2
      expect(type_klass.field_definitions["sword"].union).to eq true
      expect(type_klass.field_definitions["crossbow"].union).to eq true
    end
  end

  describe "#to_json" do
    before :each do
      Sword = Class.new
      Crossbow = Class.new
      SwordType = Class.new
      SwordType.field :damage, type: "Int"
      SwordType.can :query, fields: [:damage]
      CrossbowType = Class.new
      CrossbowType.field :damage, type: "Int"
      CrossbowType.field :range, type: "Int"
      CrossbowType.can :query, fields: [:damage, :range]
      type_klass.unions(
        {name: "sword", type: "SwordType", model_klass: "Sword"},
        {name: "crossbow", type: "CrossbowType",
          model_klass: ->{"Crossbow"}
        }
      )
      type_klass.can :query, fields: [:sword, :crossbow]
      @runner = RailsQL::Runner.new(
        query_root: type_klass,
        mutation_root: type_klass
      )
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

      allow_any_instance_of(type_klass).to receive(:model).and_return sword
      allow(sword).to receive(:kind_of?).with(Sword).and_return true
      allow(sword).to receive(:kind_of?).with(Crossbow).and_return false
      results = @runner.execute!(query: query).as_json
      expect(results.keys).to eq ["damage"]
      expect(results["damage"]).to eq 5

      allow_any_instance_of(type_klass).to receive(:model).and_return(
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
