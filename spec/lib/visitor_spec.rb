require "spec_helper"

describe RailsQL::Builder::Visitor do
  let(:query_root_builder) { instance_double "RailsQL::Builder::TypeBuilder" }
  let(:mutation_root_builder) { instance_double "RailsQL::Builder::TypeBuilder" }
  let(:visitor) {RailsQL::Builder::Visitor.new(
    query_root_builder: query_root_builder,
    mutation_root_builder: mutation_root_builder
  )}

  def visit_graphql(graphql)
    ast = GraphQL::Parser.parse(graphql)
    visitor.accept ast
  end

  before :each do
    allow_any_instance_of(double.class).to receive(
      :fragments
    ).and_return []
    allow_any_instance_of(query_root_builder.class).to receive(
      :fragments
    ).and_return []
    allow(mutation_root_builder).to receive(
      :fragments
    ).and_return []
  end

  describe "#accept" do
    it "calls builder#add_child_builder! for each child field node" do
      expect(query_root_builder).to receive(:add_child_builder!).with(
        name: 'hero'
      )

      visit_graphql "query { hero }"
    end

    context "aliases" do
      it "calls builder#add_child_builder! for each child field node" do
        expect(query_root_builder).to receive(:add_child_builder!).with(
          name: "hero",
          alias: "megaman"
        )
        visit_graphql "query { megaman: hero }"
      end

      it "parses nested fields" do
        type_builder = instance_double "RailsQL::Builder::TypeBuilder"

        expect(query_root_builder).to receive(:add_child_builder!).with(
          name: "hero",
          alias: "megaman"
        ).and_return type_builder
        expect(type_builder).to receive(:add_child_builder!).with(
          name: "reasons",
          alias: "stuff"
        )
        expect(type_builder).to receive(:add_child_builder!).with(
          name: "wat",
          alias: nil
        )

        visit_graphql "query { megaman: hero {stuff: reasons, wat} }"
      end
    end

    context "inline fragments" do
      def expect_inline_fragment(name: "moo")
        @fragment_builder = instance_double "RailsQL::Builder::FragmentBuilder"
        type_builder = instance_double "RailsQL::Builder::FragmentBuilder"

        expect(RailsQL::Builder::FragmentBuilder).to receive(:new)
          .and_return @fragment_builder
        expect(query_root_builder).to receive(:add_fragment_builder!).with(
          @fragment_builder
        ).and_return @fragment_builder
        expect(@fragment_builder).to receive(:add_child_builder!).with(
          name: name
        )
        allow(query_root_builder).to receive(:type_klass).and_return(
          :query_root_and_stuff
        )
        expect(RailsQL::Builder::TypeBuilder).to receive(:new).with(
          type_klass: :query_root_and_stuff
        ).and_return type_builder
        expect(@fragment_builder).to receive(:type_builder=).with(
          type_builder
        )
      end

      context "without a TypeCondition" do
        it "builds an inline fragment" do
          expect_inline_fragment
          visit_graphql <<-GraphQL
            query {
              ... {
                moo
              }
            }
          GraphQL
        end
        it "builds multiple inline fragments" do
          pending "figuring out how to write this"
          fail
          expect_inline_fragment
          expect_inline_fragment name: "moo2"
          visit_graphql <<-GraphQL
            query {
              ... {
                moo
              }
              ... {
                moo2
              }
            }
          GraphQL
        end

      end

      context "with a TypeCondition" do
        it "builds an inline fragment" do
          expect_inline_fragment
          type_builder = instance_double "RailsQL::Builder::TypeBuilder"
          expect(RailsQL::Builder::TypeBuilder).to receive(:new).with(
            type_klass: "CowRoot"
          ).and_return type_builder
          expect(@fragment_builder).to receive(:type_builder=).with(
            type_builder
          )

          visit_graphql <<-GraphQL
            query {
              ... on CowRoot {
                moo
              }
            }
          GraphQL
        end
      end
    end

    it "calls for each subscription" do
      pending
      fail
      visit_graphql "subscription heroQuery{ hero }"
    end

    describe "fragments" do
      before :each do
        @fragment_builder = instance_double "RailsQL::Builder::FragmentBuilder"
        type_builder = instance_double "RailsQL::Builder::TypeBuilder"

        expect(RailsQL::Builder::FragmentBuilder).to receive(:new).with(
          fragment_name: "heroFieldsFragment"
        ).and_return @fragment_builder
        expect(RailsQL::Builder::TypeBuilder).to receive(:new).and_return(
          type_builder
        )
        expect(@fragment_builder).to receive(:type_builder=).with(
          type_builder
        )
        expect(query_root_builder).to receive(:add_fragment_builder!).with(
          @fragment_builder
        ).and_return @fragment_builder
      end

      context "when the fragment is defined before the spread" do
        it "builds fragment_builder and calls add_child_builder with field names" do
          expect(@fragment_builder).to receive(:add_child_builder!).with(
            name: "name"
          )
          visit_graphql <<-GraphQL
            fragment heroFieldsFragment on Root { name }
            query { ...heroFieldsFragment }
          GraphQL
        end
      end

      context "when the fragment is defined after the spread" do
        it "builds fragment_builder and calls add_child_builder with field names" do
          expect(@fragment_builder).to receive(:add_child_builder!).with(
            name: "name"
          )
          visit_graphql <<-GraphQL
            query { ...heroFieldsFragment }
            fragment heroFieldsFragment on Root { name }
         GraphQL
        end
      end

      context "when a fragment contains a circular refence" do
        it "raises InvalidFragment error" do
          allow(@fragment_builder).to receive(:add_fragment_builder!).with(
            @fragment_builder
          ).and_return @fragment_builder

          expect{ visit_graphql(<<-GraphQL) }.to raise_error
            query { ...heroFieldsFragment }
            fragment heroFieldsFragment on Root {
              ...heroFieldsFragment
            }
          GraphQL
        end
      end
    end

    context "when mutations are present" do
      it "follows query workflow but applies it to the mutation_root_builder" do
        expect(query_root_builder).to_not receive(:add_child_builder!).with(
          name: 'createHero'
        )
        expect(mutation_root_builder).to receive(:add_child_builder!).with(
          name: 'createHero'
        )

        visit_graphql <<-GraphQL
          mutation {
            createHero
          }
        GraphQL
      end
    end

    context "with args" do
      it "adds input objects" do
        hero_builder = instance_double "RailsQL::Type::Builder"
        stuff_builder = instance_double "RailsQL::Type::Builder"
        allow(query_root_builder).to receive(:add_child_builder!).and_return(
          hero_builder
        )
        allow(hero_builder).to receive(:is_input?).and_return false
        expect(hero_builder).to receive(:add_arg_builder!).with(
          name: "stuff",
          model: nil
        ).and_return stuff_builder
        expect(stuff_builder).to receive(:add_child_builder!).with(
          name: "reasons",
          model: "5"
        )
        allow(stuff_builder).to receive(:is_input?).and_return true

        visit_graphql "query { hero(stuff: {reasons: 5}) }"
      end

      it "calls builder#add_arg_builder! for each arg" do
        hero_builder = instance_double "RailsQL::Type::Builder"
        allow(query_root_builder).to receive(:add_child_builder!).and_return(
          hero_builder
        )
        allow(hero_builder).to receive(:is_input?).and_return false
        expect(hero_builder).to receive(:add_arg_builder!).with(
          name: "id",
          model: "3"
        )

        visit_graphql "query { hero(id: 3) }"
      end
    end

    context "operations" do
      before :each do
        allow(query_root_builder).to receive :add_child_builder!
        allow(mutation_root_builder).to receive :add_child_builder!
      end

      it "sets the operation name to nil for anonomous operations" do
        visit_graphql <<-GraphQL
          query {name}
        GraphQL

        expect(visitor.operations.first.name).to eq nil
      end

      it "sets the operation name" do
        visit_graphql <<-GraphQL
          query Thing {name}
        GraphQL

        expect(visitor.operations.first.name).to eq "Thing"
      end

      it "sets the operation's operation_type" do
        visit_graphql <<-GraphQL
          mutation {name}
        GraphQL

        expect(visitor.operations.first.operation_type).to eq :mutation
      end

      context "variables" do

        # before :each do
        #   expect(query_builder)
        # end

        def expect_default_value_builder(type_klass:, model:)
          default_val_builder = instance_double "RailsQL::Builder::TypeBuilder"
          expect(RailsQL::Builder::TypeBuilder).to receive(:new).with(
            type_klass: type_klass,
            model: model,
            is_input: true
          ).and_return default_val_builder
          allow(default_val_builder).to receive(:is_input?).and_return true
          return default_val_builder
        end

        it "adds variable builders to the operation" do
          default_val_builder = expect_default_value_builder(
            type_klass: "CowType95",
            model: "1337"
          )

          visit_graphql <<-GraphQL
            query($cow: CowType95 = 1337, $pig: WatType) {lol}
          GraphQL

          var_builders = visitor.operations.first.variable_builders
          expect(var_builders.length).to eq 2
          expect(var_builders["cow"].variable_name).to eq "cow"
          expect(var_builders["cow"].type_klass).to eq "CowType95"
          expect(var_builders["cow"].default_value_builder).to eq(
            default_val_builder
          )
          expect(var_builders["pig"].variable_name).to eq "pig"
          expect(var_builders["pig"].type_klass).to eq "WatType"
          expect(var_builders["pig"].default_value).to eq nil
        end

        it "adds object-valued variable builders to the operation" do
          default_val_builder = expect_default_value_builder(
            type_klass: "CowType95",
            model: nil
          )
          expect(default_val_builder).to(receive :add_child_builder!).with(
            name: "test",
            model: "wat"
          )

          visit_graphql <<-GraphQL
            query($cow: CowType95 = {test: "wat"}) {lol}
          GraphQL

          var_builders = visitor.operations.first.variable_builders
          expect(var_builders.length).to eq 1
          expect(var_builders["cow"].variable_name).to eq "cow"
          expect(var_builders["cow"].type_klass).to eq "CowType95"
          expect(var_builders["cow"].default_value_builder).to eq(
            default_val_builder
          )
        end
      end

      context "multiple operations in a single query document" do
        context "without names" do
          it "throws an error" do
            hero_builder = instance_double "RailsQL::Type::Builder"
            allow(query_root_builder).to(
              receive(:add_child_builder!).and_return hero_builder
            )

            expect{ visit_graphql <<-GraphQL }.to raise_error
              query {
                hero {name}
              }
              query {
                hero {description}
              }
            GraphQL
          end
        end

        context "with names" do
          it "instantiates a root builder for each operation" do
            expect(mutation_root_builder).to receive(:add_child_builder!).with(
              name: 'createHero'
            )
            expect(query_root_builder).to receive(:add_child_builder!).with(
              name: 'name'
            )

            visit_graphql <<-GraphQL
              mutation A {
                createHero
              }
              query B {
                name
              }
            GraphQL

            expect(visitor.operations.map(&:name)).to eq ["A", "B"]
          end
        end

      end
    end

    context "with variable references" do
      it "adds variables references to the builder" do
        @hero_builder = instance_double "RailsQL::Type::Builder"
        expect(query_root_builder).to receive(:add_child_builder!).with(
          name: 'createHero'
        ).and_return @hero_builder
        expect(@hero_builder).to receive(:add_variable).with(
          argument_name: "hero",
          variable_name: "cow"
        )
        visit_graphql <<-GraphQL
          query {
            createHero(hero: $cow)
          }
        GraphQL
      end
    end

  end
end
