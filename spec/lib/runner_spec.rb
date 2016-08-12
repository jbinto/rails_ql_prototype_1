require "spec_helper"

describe RailsQL::Runner do
  describe "#execute!" do

    it "queries a type for a field" do
      cat_type_klass = Class.new(RailsQL::Type) do
        field(:names,
          type: "[String]",
          resolve: ->(args, child_query) {
            (0..1).map {|i|"Fuzzy #{model} #{i}"}
          }
        )
      end
      root_type_klass = Class.new(RailsQL::Type) do
        field(:my_cats,
          type: cat_type_klass,
          resolve: ->(args, child_query) {"The Cat"}
         )
      end

      runner = described_class.new(
        query_root: root_type_klass,
        mutation_root: nil
      )
      root_type = runner.execute! query: <<-GRAPHQL
        {fuzzy_teh_cat: my_cats {names}}
      GRAPHQL

      expect(root_type.as_json).to eq(
        "fuzzy_teh_cat" =>
        {
          "names" =>
          [
            "Fuzzy The Cat 0",
            "Fuzzy The Cat 1"
          ]
        }
      )
    end

  end
end
