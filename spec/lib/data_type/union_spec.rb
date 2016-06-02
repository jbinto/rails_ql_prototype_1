require "spec_helper"

describe RailsQL::DataType::Union do
  let(:data_type_klass) {Class.new described_class}


  describe ".unions" do
    it "creates field defintitions" do
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
end
