require "spec_helper"

describe RailsQL::Visitor do
  let(:query_root_builder) { instance_double "RailsQL::Type::Builder" }
  let(:mutation_root_builder) { instance_double "RailsQL::Type::Builder" }
  let(:visitor) {RailsQL::Visitor.new(
    query_root_builder: query_root_builder,
    mutation_root_builder: mutation_root_builder
  )}

  def visit_graphql(graphql)
    ast = GraphQL::Parser.parse(graphql)
    visitor.accept ast
  end

  before :each do
    allow_any_instance_of(double.class).to receive(
      :unresolved_fragments
    ).and_return []
    allow_any_instance_of(query_root_builder.class).to receive(
      :unresolved_fragments
    ).and_return []
    allow(mutation_root_builder).to receive(
      :unresolved_fragments
    ).and_return []
  end

  describe "#accept" do
    it "calls builder#add_child_builder for each child field node" do
      expect(query_root_builder).to receive(:add_child_builder).with 'hero'

      visit_graphql "query { hero }"
    end

    it "calls builder#add_arg for each arg" do
      hero_builder = instance_double "RailsQL::Type::Builder"
      allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
      expect(hero_builder).to receive(:add_arg).with('id', 3)

      visit_graphql "query { hero(id: 3) }"
    end

    def union_setup
      hero_builder = double
      weapon_builder = instance_double "RailsQL::Type::Builder"
      sheathe_builder = instance_double "RailsQL::Type::Builder"
      sword_builder = instance_double "RailsQL::Type::Builder"
      crossbow_builder = instance_double "RailsQL::Type::Builder"
      allow(query_root_builder).to receive(:add_child_builder).with(
        "hero"
      ).and_return hero_builder
      allow(hero_builder).to receive(:add_child_builder).with(
        "weapon"
      ).and_return weapon_builder
      expect(weapon_builder).to receive(:add_child_builder).with(
        "sword"
      ).and_return(sword_builder)
      expect(sword_builder).to receive(:add_child_builder).with(
        "damage"
      )
      expect(sword_builder).to receive(:add_child_builder).with(
        "sheathe"
      ).and_return sheathe_builder
      expect(sheathe_builder).to receive(:add_child_builder).with "length"
      expect(weapon_builder).to receive(:add_child_builder).with(
        "crossbow"
      ).and_return crossbow_builder
      expect(crossbow_builder).to receive(:add_child_builder).with(
        "damage"
      )
      expect(crossbow_builder).to receive(:add_child_builder).with(
        "range"
      )
    end

    it "calls builder#add_child_builder for each union child field node when defined in fragment" do
      union_setup

      visit_graphql("
        query {
          hero {
            weapon {
              ... on Sword {
                damage
                sheathe {
                  length
                }
              }
              ... on Crossbow {
                damage
                range
              }
            }
          }
        }
      ")
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
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
          expect(hero_builder).to receive(:add_child_builder).with 'name'

          visit_graphql "
            fragment heroFieldsFragment on Hero { name }
            query { hero { ...heroFieldsFragment } }
          "
        end

        it "calls builder#add_arg for each arg in a fragment" do
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
          expect(hero_builder).to receive(:add_arg).with('id', 3)

          visit_graphql "
            fragment heroFieldsFragment on Stuff { hero(id: 3) }
            query { ...heroFieldsFragment }
          "
        end

        it "calls builder#add_child_builder for each union child field node when defined in fragment" do
          union_setup

          visit_graphql("
            fragment weaponFrag on Hero {
              weapon {
                ... on Sword {
                  damage
                  sheathe {
                    length
                  }
                }
                ... on Crossbow {
                  damage
                  range
                }
              }
            }
            query {
              hero {
                ...weaponFrag
              }
            }
          ")
        end
      end

      context "when the fragment is defined after the spread" do
        it "parses queries with fragments into data types" do
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
          expect(hero_builder).to receive(:add_child_builder).with 'name'

          visit_graphql "
            query { hero { ...heroFieldsFragment } }
            fragment heroFieldsFragment on Hero { name }
          "
        end
      end

      context "when the nested fragment is defined before the nested spread" do
        it "parses queries with nested fragments into data types" do
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
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
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
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
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
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

      context "when two nested fragments are defined before the nested spread" do
        it "parses queries with nested fragments into data types" do
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          expect(hero_builder).to receive(:add_child_builder).with 'description'
          expect(hero_builder).to receive(:add_child_builder).with 'icon'

          visit_graphql "
            fragment frag2 on Hero { ...frag3 }
            fragment frag3 on Hero {
              description
              icon
            }
            fragment heroFieldsFragment on Hero {
              name
            }
            query { hero {
              ...heroFieldsFragment
              ...frag2
            } }
          "
        end
      end

      context "when the nested fragment is not a grandchild of the fragment" do
        it "parses queries with nested fragments into data types" do
          hero_builder = double
          allow(query_root_builder).to receive(:add_child_builder).with(
            'hero'
          ).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          pet_builder = instance_double "RailsQL::Type::Builder"
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
          allow(query_root_builder).to receive(:add_child_builder).with(
            'hero'
          ).and_return hero_builder
          allow(hero_builder).to receive(:add_child_builder).with 'name'
          pet_builder = instance_double "RailsQL::Type::Builder"
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

      context "when a fragment cycle is circular" do
        it "raises InvalidFragment error" do
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return hero_builder
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
    end

    context "when mutations are present" do
      it "follows query workflow but applies it to the mutation_root_builder" do
        hero_builder = instance_double "RailsQL::Type::Builder"
        expect(query_root_builder).to_not receive(:add_child_builder).with(
          'createHero'
        )
        expect(mutation_root_builder).to receive(:add_child_builder).with(
          'createHero'
        ).and_return hero_builder
        expect(hero_builder).to receive(:add_arg).with(
          :hero, {name: "Cloud", weapon: {damage: 6}}
        )
        expect(hero_builder).to receive(:add_child_builder).with(
          'name'
        )

        visit_graphql "mutation {
          createHero(hero: {
            name: \"Cloud\",
            weapon: {
              damage: 6
            }
          }){ name }
        }"
      end
    end

    context "with variables" do
      before :each do
        @hero_builder = instance_double "RailsQL::Type::Builder"
        allow(mutation_root_builder).to receive(:add_child_builder).with(
          'createHero'
        ).and_return @hero_builder
        allow(@hero_builder).to receive(:add_child_builder).with(
          'name'
        )
      end

      context "when the operation defines the variable" do
        it "adds the variables in the operation to the builder" do
          expect(@hero_builder).to receive(:add_variable).with(
            argument_name: "hero",
            variable_name: "cow",
            variable_type_name: "CowType"
          )
          visit_graphql <<-GraphQL
            mutation Thing($cow: CowType) {
              createHero(hero: $cow){ name }
            }
          GraphQL
        end

        it "adds the variables in a fragment to the builder" do
          expect(@hero_builder).to receive(:add_variable).with(
            argument_name: "hero",
            variable_name: "cow",
            variable_type_name: "CowType"
          )
          visit_graphql <<-GraphQL
            mutation Thing($cow: CowType) {
              ...cowFragment
            }
            fragment cowFragment on Stuff {
              createHero(hero: $cow){ name }
            }
          GraphQL
        end
      end

      context "when the operation does not define the variable" do
        it "errors on variables in the operation" do
          expect{
            visit_graphql <<-GraphQL
              mutation() {
                createHero(hero: $cow){ name }
              }
            GraphQL
          }.to raise_error
        end

        it "errors on variables in a fragment" do
          expect{
            visit_graphql <<-GraphQL
              mutation() {
                ...cowFragment
              }
              cowFragment on Stuff {
                createHero(hero: $cow){ name }
              }
            GraphQL
          }.to raise_error
        end
      end
    end

    context "multiple operations in a single query document" do
      context "without names" do
        it "throws an error" do
          hero_builder = instance_double "RailsQL::Type::Builder"
          allow(query_root_builder).to receive(:add_child_builder).and_return(
            hero_builder
          )

          expect{
            visit_graphql "
              query {
                hero {name}
              }
              query {
                hero {description}
              }
            "
          }.to raise_error
        end
      end

      context "with names" do
        it "instantiates query + mutation roots for each operation" do
          hero_builder = double
          allow(query_root_builder).to receive(:add_child_builder).with(
            'hero'
          ).and_return hero_builder
          allow(mutation_root_builder).to receive(:add_child_builder).with(
            'createHero'
          ).and_return hero_builder
          expect(hero_builder).to receive(:add_arg).with(
            :hero, {name: "Cloud", weapon: {damage: 6}}
          )
          allow(hero_builder).to receive(:add_child_builder).with('name')

          visit_graphql "
            fragment heroFields on Hero {
              name
            }
            mutation A {
              createHero(hero: {
                name: \"Cloud\",
                weapon: {
                  damage: 6
                }
              }){ ...heroFields }
            }
            query B {
              hero {...heroFields}
            }
            query C {
              hero {...heroFields}
            }
          "

          expect(visitor.root_builders.length).to eq 3
          # expect(visitor.root_builders.keys).to eq ["A", "B", "C"]
        end
      end
    end
  end
end
