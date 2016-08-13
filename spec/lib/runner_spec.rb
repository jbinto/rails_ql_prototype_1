require "spec_helper"

describe RailsQL::Runner do
  describe "#execute!" do

    it "queries a type for a field" do
      cat_type_klass = Class.new(RailsQL::Type) do
        field(:names,
          type: "[!String]",
          resolve: ->(args, child_query) {(0..1).map{|n|"Fuzzy #{model} #{n}"}}
        )
      end
      root_type_klass = Class.new(RailsQL::Type) do
        field(:my_cat,
          type: cat_type_klass,
          resolve: ->(args, child_query) {"The Cat"}
         )
      end

      runner = described_class.new(
        query_root: root_type_klass,
        mutation_root: nil
      )
      root_type = runner.execute! query: <<-GRAPHQL
        {fuzzy_teh_cat: my_cat {names}}
      GRAPHQL

      expect(root_type.as_json).to eq(
        "fuzzy_teh_cat" => {
          "names" => ["Fuzzy The Cat 1", "Fuzzy The Cat 2"]
        }
      )
    end

  end
end
