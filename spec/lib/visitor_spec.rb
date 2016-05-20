require "spec_helper"

describe RailsQL::Visitor do
  let(:root_builder) { instance_double "RailsQL::DataType::Builder" }
  let(:visitor) {RailsQL::Visitor.new(root_builder)}

  def visit_graphql(graphql)
    ast = GraphQL::Parser.parse(graphql)
    visitor.accept ast
  end

  describe "#accept" do
    it "calls builder#add_child_builder for each child field node" do
      expect(root_builder).to receive(:add_child_builder).with 'hero'

      visit_graphql "query { hero }"
    end

    it "calls builder#add_arg for each arg" do
      hero_builder = double
      allow(root_builder).to receive(:add_child_builder).and_return hero_builder
      expect(hero_builder).to receive(:add_arg).with('id', 3)

      visit_graphql "query { hero(id: 3) }"
    end

    it "calls for each subscription" do
      pending
      fail
      visit_graphql "subscription heroQuery{ hero }"
    end

    it "calls for each mutation" do
      pending
      fail
      visit_graphql "mutation updateHero{ hero }"
    end

    describe "fragments" do

      context "when the fragment is defined before the spread" do
        it "parses queries with fragments into data types" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          expect(hero_builder).to receive(:add_child_builder).with 'name'

          visit_graphql "
            fragment heroFieldsFragment on Hero { name }
            query { hero { ...heroFieldsFragment } }
          "
        end
      end

      context "when the fragment is defined after the spread" do
        it "parses queries with fragments into data types" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          expect(hero_builder).to receive(:add_child_builder).with 'name'

          visit_graphql "
            query { hero { ...heroFieldsFragment } }
            fragment heroFieldsFragment on Hero { name }
          "
        end
      end

      context "when the nested fragment is defined before the nested spread" do
        it "parses queries with nested fragments into data types" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          expect(hero_builder).to receive(:add_child_builder).with 'description'

          visit_graphql "
            fragment extraFieldFragment on Hero { description }
            query { hero { ...heroFieldsFragment } }
            fragment heroFieldsFragment on Hero {
              name
              ...extraFieldFragment
            }
          "
        end
      end

      context "when the nested fragment is defined after the nested spread" do
        it "parses queries with nested fragments into data types" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          expect(hero_builder).to receive(:add_child_builder).with 'description'

          visit_graphql "
            query { hero { ...heroFieldsFragment } }
            fragment heroFieldsFragment on Hero {
              name
              ...extraFieldFragment
            }
            fragment extraFieldFragment on Hero { description }
          "
        end
      end

      context "when the nested fragment is defined before the nested spread" do
        it "parses queries with nested fragments into data types" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          expect(hero_builder).to receive(:add_child_builder).with 'description'

          visit_graphql "
            fragment extraFieldFragment on Hero { description }
            fragment heroFieldsFragment on Hero {
              name
              ...extraFieldFragment
            }
            query { hero { ...heroFieldsFragment } }
          "
        end
      end

      context "when the nested fragment is defined before the nested spreadz" do
        it "parses queries with nested fragments into data types" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          expect(hero_builder).to receive(:add_child_builder).with 'description'

          visit_graphql "
            fragment frag2 on Hero { ...frag3 }
            fragment frag3 on Hero { description }
            fragment heroFieldsFragment on Hero {
              name
              ...extraFieldFragment
            }
            query { hero {
              ...heroFieldsFragment
              ...frag2
            } }
            fragment extraFieldFragment on Hero { ...frag3 }
          "
        end
      end

      # for each spread
      #   if within fragment,
      #     add to fragments tree
      #   if within data_type
      #     add to data_type.unresolved_fragments
      #   if within data_type within fragment
      #     add to fragment[:fields].select {|f| f[:name] == data_type }.first[:fragments]
      # for each definition,
      #   fragments[frag_name] = {
      #     fields: [],
      #     fragments: {}
      #   }
      # for each field
      #   if within fragment
      #     add {name: <field_name>, fields: {}, fragments: {}} to current_fragment[:fields]
      #   if within data_type
      #     add_child_builder field_name
      #   if within data_type within fragment
      #     add {name: <field_name>, fields: {}, fragments: {}} to parent field in current_fragment[:fields]

      # for each data_type
      #   add to data_types

      # at document_end
      #   for each data_type in data_types
      #     for each unresolved_fragment in data_type.unresolved_fragments
      #       traverse down fields in each fragment[:fields] and fragment[:fragments].map [:fields], adding children builders as you go


      context "when a fragment cycle is circular" do
        it "raises InvalidFragment error" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          allow(hero_builder).to receive(:add_child_builder).with 'friends'

          expect{visit_graphql("
            query { hero { ...heroFieldsFragment } }
            fragment heroFieldsFragment on Hero {
              name
              friends {
                ...heroFieldsFragment
              }
            }
          ")}.to raise_error
        end
      end

      context "when the nested fragment is not a grandchild of the fragment" do
        it "parses queries with nested fragments into data types" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          pet_builder = double
          expect(hero_builder).to receive(:add_child_builder).with('pets').and_return(
            pet_builder
          )
          expect(pet_builder).to receive(:add_child_builder).with 'description'
          expect(pet_builder).to receive(:add_child_builder).with 'other_field'

          visit_graphql "
            query { hero { ...heroFieldsFragment } }
            fragment heroFieldsFragment on Hero {
              name
              pets {
                ...extraFieldFragment
                other_field
              }
            }
            fragment extraFieldFragment on Pet { description }
          "
        end
      end

      context "when the nested fragment is defined after the nested spread and is not a grandchild of the fragment" do
        it "parses queries with nested fragments into data types" do
          hero_builder = double
          allow(root_builder).to receive(:add_child_builder).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          pet_builder = double
          expect(hero_builder).to receive(:add_child_builder).with('pets').and_return(
            pet_builder
          )
          expect(pet_builder).to receive(:add_child_builder).with 'description'

          visit_graphql "
            fragment extraFieldFragment on Hero { description }
            query { hero { ...heroFieldsFragment } }
            fragment heroFieldsFragment on Hero {
              name
              pets {
                ...extraFieldFragment
              }
            }
          "
        end
      end
    end

  end
end

