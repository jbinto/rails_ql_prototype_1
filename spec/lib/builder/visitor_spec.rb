require "spec_helper"
require_relative "./visitor_spec_helper"

describe RailsQL::Builder::Visitor do
  let(:visitor) {RailsQL::Builder::Visitor.new}
  let(:root_builder) {visitor.operations.first.root_builder}

  def visit_graphql(graphql)
    ast = GraphQL::Parser.parse graphql
    visitor.accept ast
  end

  def names_and_aliases_in(parent_builder)
    parent_builder.child_builders.map do |child_builder|
      {
        name: child_builder.name,
        aliased_as: child_builder.aliased_as
      }
    end
  end

  describe "#accept" do
    it "adds a builder for a field" do
      visit_graphql "query { hero }"

      expect(names_and_aliases_in root_builder).to eq [{
        name: "hero",
        aliased_as: "hero"
      }]
    end

    context "aliases" do
      it "adds a builder for a field" do
        visit_graphql "query { megaman: hero }"

        expect(names_and_aliases_in root_builder).to eq [{
          name: "hero",
          aliased_as: "megaman"
        }]
      end

      it "adds nested builders for nested fields" do
        visit_graphql "query { megaman: hero {stuff: reasons, wat} }"
        hero_builder = root_builder.child_builders.first

        expect(names_and_aliases_in hero_builder).to eq [
          {
            name: "reasons",
            aliased_as: "stuff"
          },
          {
            name: "wat",
            aliased_as: "wat"
          }
        ]
      end
    end

    context "directives" do
      # context "on fields" do
      #   before :each do
      #     @hero_type_builder = instance_double RailsQL::Builder::TypeBuilder
      #
      #     allow(query_root_builder).to receive(:add_child_builder!)
      #       .and_return @hero_type_builder
      #   end
      #
      #   it "parses directive on a field" do
      #     expect_directive_builder(
      #       type_klass: "dancy",
      #       on: @hero_type_builder
      #     )
      #     visit_graphql "query { hero @dancy }"
      #   end
      #
      #   it "parses directive on an aliased field" do
      #     expect(query_root_builder).to receive(:add_child_builder!).with(
      #       name: "hero",
      #       aliased_as: "danceMaster"
      #     )
      #     expect_directive_builder(
      #       type_klass: "dancy",
      #       on: @hero_type_builder
      #     )
      #     visit_graphql "query { danceMaster: hero @dancy }"
      #   end
      #
      #   it "parses directive with args on a field" do
      #     directive_builder = expect_directive_builder(
      #       type_klass: "dancy",
      #       on: @hero_type_builder
      #     )
      #
      #     arg_builder = instance_double RailsQL::Builder::TypeBuilder
      #     allow(directive_builder).to receive(:arg_builder).and_return(
      #       arg_builder
      #     )
      #     allow(arg_builder).to receive(:is_input?).and_return true
      #     expect(arg_builder).to receive(:add_child_builder!).with(
      #       name: "moo",
      #       model: "foo"
      #     )
      #
      #     visit_graphql "query { hero @dancy(moo: \"foo\") }"
      #   end
      #
      #   it "parses multiple directives on a field" do
      #     ["dancy", "dancy", "fancy"].each do |type_klass|
      #       expect_directive_builder(
      #         type_klass: type_klass,
      #         on: @hero_type_builder
      #       )
      #     end
      #
      #     visit_graphql "query { hero @dancy @dancy @fancy }"
      #   end
      # end
      #
      # context "on an operation" do
      #   it "adds the directive to the query" do
      #     directive_builder = expect_directive_builder(
      #       type_klass: "dancy",
      #       on: query_root_builder
      #     )
      #
      #     expect(query_root_builder).to receive(:add_child_builder!).with(
      #       name: "hero",
      #       aliased_as: nil
      #     )
      #
      #     visit_graphql "query @dancy { hero }"
      #   end
      #
      #   it "adds the directive to the mutation" do
      #     directive_builder = expect_directive_builder(
      #       type_klass: "dancy",
      #       on: mutation_root_builder
      #     )
      #
      #     expect(mutation_root_builder).to receive(:add_child_builder!).with(
      #       name: "createHero",
      #       aliased_as: nil
      #     )
      #
      #     visit_graphql "mutation A @dancy { createHero }"
      #   end
      # end

      # context "on a fragment spread" do
      #   it "adds the directive to the fragment spread" do
      #     pending
      #
      #     visit_graphql <<-GraphQL
      #       query { ...heroFragment @dancy }
      #       fragment heroFragment on Hero {name}
      #     GraphQL
      #   end
      # end
      #
      # context "on a fragment definition" do
      #   it "adds the directive to the fragment builder" do
      #     # so much boilerplate...
      #
      #     ## arrange the mock type_builder for `Hero` type
      #     type_builder = instance_double "RailsQL::Builder::TypeBuilder"
      #     expect(RailsQL::Builder::TypeBuilder).to receive(:new).and_return(type_builder)
      #
      #     ## arrange the mock fragment_builder for `heroFragment`
      #     fragment_builder = instance_double "RailsQL::Builder::FragmentBuilder"
      #     expect(RailsQL::Builder::FragmentBuilder).to receive(:new).and_return(fragment_builder)
      #
      #     ## arrange the mock directive_builder for `Dancy`
      #     directive_builder = instance_double "RailsQL::Builder::DirectiveBuilder"
      #     expect(RailsQL::Builder::DirectiveBuilder).to receive(:new).and_return(directive_builder)
      #
      #     ## don't overlap other tests / overtest: use allow instead of expect here to make rspec happy
      #     allow(query_root_builder).to receive(:add_fragment_builder!)
      #     allow(directive_builder).to receive(:arg_builder)
      #     allow(fragment_builder).to receive(:add_child_builder!)
      #     allow(fragment_builder).to receive(:type_builder=)
      #
      #     ## here is the only actual assertion! SO MUCH MOCKING UGH
      #     expect(fragment_builder).to receive(:add_directive_builder!).with(directive_builder)
      #
      #     visit_graphql <<-GraphQL
      #       query { ...heroFragment }
      #       fragment heroFragment on Hero @dancy {name}
      #     GraphQL
      #   end
      # end

    end
    #
    # context "inline fragments" do
    #   context "without a TypeCondition" do
    #     it "builds an inline fragment" do
    #       expect_inline_fragment
    #       visit_graphql <<-GraphQL
    #         query {
    #           ... {
    #             moo
    #           }
    #         }
    #       GraphQL
    #     end
    #     it "builds multiple inline fragments" do
    #       pending "figuring out how to write this"
    #       fail
    #       expect_inline_fragment
    #       expect_inline_fragment name: "moo2"
    #       visit_graphql <<-GraphQL
    #         query {
    #           ... {
    #             moo
    #           }
    #           ... {
    #             moo2
    #           }
    #         }
    #       GraphQL
    #     end
    #
    #   end
    #
    #   context "with a TypeCondition" do
    #     it "builds an inline fragment" do
    #       expect_inline_fragment
    #       type_builder = instance_double "RailsQL::Builder::TypeBuilder"
    #       expect(RailsQL::Builder::TypeBuilder).to receive(:new).with(
    #         type_klass: "CowRoot"
    #       ).and_return type_builder
    #       expect(@fragment_builder).to receive(:type_builder=).with(
    #         type_builder
    #       )
    #
    #       visit_graphql <<-GraphQL
    #         query {
    #           ... on CowRoot {
    #             moo
    #           }
    #         }
    #       GraphQL
    #     end
    #   end
    # end
    #
    # it "calls for each subscription" do
    #   pending
    #   fail
    #   visit_graphql "subscription heroQuery{ hero }"
    # end

    context "fragments" do
    #   before :each do
    #     @fragment_builder = instance_double "RailsQL::Builder::FragmentBuilder"
    #     type_builder = instance_double "RailsQL::Builder::TypeBuilder"
    #
    #     expect(RailsQL::Builder::FragmentBuilder).to receive(:new).with(
    #       fragment_name: "heroFieldsFragment"
    #     ).and_return @fragment_builder
    #     expect(RailsQL::Builder::TypeBuilder).to receive(:new).and_return(
    #       type_builder
    #     )
    #     expect(@fragment_builder).to receive(:type_builder=).with(
    #       type_builder
    #     )
    #     expect(query_root_builder).to receive(:add_fragment_builder!).with(
    #       @fragment_builder
    #     ).and_return @fragment_builder
    #   end
    #
    #   context "when the fragment is defined before the spread" do
    #     it "builds fragment_builder and calls add_child_builder with field names" do
    #       expect(@fragment_builder).to receive(:add_child_builder!).with(
    #         name: "name",
    #         aliased_as: nil
    #       )
    #       visit_graphql <<-GraphQL
    #         fragment heroFieldsFragment on Root { name }
    #         query { ...heroFieldsFragment }
    #       GraphQL
    #     end
    #   end
    #
    #   context "when the fragment is defined after the spread" do
    #     it "builds fragment_builder and calls add_child_builder with field names" do
    #       expect(@fragment_builder).to receive(:add_child_builder!).with(
    #         name: "name",
    #         aliased_as: nil
    #       )
    #       visit_graphql <<-GraphQL
    #         query { ...heroFieldsFragment }
    #         fragment heroFieldsFragment on Root { name }
    #      GraphQL
    #     end
    #   end
    #
    #   context "when a fragment contains a circular refence" do
    #     it "raises InvalidFragment error" do
    #       allow(@fragment_builder).to receive(:add_fragment_builder!).with(
    #         @fragment_builder
    #       ).and_return @fragment_builder
    #
    #       expect{ visit_graphql(<<-GraphQL) }.to raise_error
    #         query { ...heroFieldsFragment }
    #         fragment heroFieldsFragment on Root {
    #           ...heroFieldsFragment
    #         }
    #       GraphQL
    #     end
    #   end
    end

    context "when mutations are present" do
      it "follows query workflow" do
        visit_graphql <<-GRAPHQL
          mutation { createHero }
        GRAPHQL

        expect(names_and_aliases_in root_builder).to eq [{
          name: "createHero",
          aliased_as: "createHero"
        }]
      end
    end

    context "with args" do
      it "adds type builders for scalars" do
        visit_graphql <<-GRAPHQL
          query { hero(id: 3) }
        GRAPHQL

        hero_builder = root_builder.child_builders.first
        args_builder = hero_builder.arg_type_builder
        id_builder = args_builder.child_builders.first
        input_builders = [args_builder, id_builder]

        expect(names_and_aliases_in hero_builder).to eq []
        expect(names_and_aliases_in args_builder).to eq [{
          name: "id",
          aliased_as: "id"
        }]
        expect(id_builder.model).to eq "3"
        expect(input_builders.all? &:is_input?).to eq true
      end

      it "adds type builders for input objects" do
        visit_graphql "query { hero(stuff: {reasons: 5}) }"

        hero_builder = root_builder.child_builders.first
        args_builder = hero_builder.arg_type_builder
        stuff_builder = args_builder.child_builders.first
        reasons_builder = stuff_builder.child_builders.first
        input_builders = [args_builder, stuff_builder, reasons_builder]

        expect(names_and_aliases_in hero_builder).to eq []
        expect(names_and_aliases_in args_builder).to eq [{
          name: "stuff",
          aliased_as: "stuff"
        }]
        expect(names_and_aliases_in stuff_builder).to eq [{
          name: "reasons",
          aliased_as: "reasons"
        }]
        expect(reasons_builder.model).to eq "5"
        expect(input_builders.all? &:is_input?).to eq true
      end
    end

    context "containing lists" do
      it "adds type builders for each scalar in the list" do
        visit_graphql "query { hero(ids: [1, 2, 3]) }"

        hero_builder = root_builder.child_builders.first
        args_builder = hero_builder.arg_type_builder
        ids_builder = args_builder.child_builders.first

        expect(ids_builder.child_builders.length).to eq 3
        expect(ids_builder.child_builders.map &:model).to eq ["1", "2", "3"]
        expect(ids_builder.child_builders.all? &:is_input?).to eq true
      end

      it "adds type builders for each input object in the list" do
        visit_graphql "query { hero(id_objs: [{id: 1}, {id: 2}]) }"

        hero_builder = root_builder.child_builders.first
        args_builder = hero_builder.arg_type_builder
        id_objs_builder = args_builder.child_builders.first
        scalar_builders = id_objs_builder.child_builders
          .map(&:child_builders)
          .flatten

        expect(id_objs_builder.child_builders.length).to eq 2
        expect(id_objs_builder.child_builders.all? &:is_input?).to eq true
        expect(scalar_builders.map &:name).to eq ["id", "id"]
        expect(scalar_builders.map &:model).to eq ["1", "2"]
      end
    end

    context "operations" do

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
        pending "variables dev time"
        #
        # # before :each do
        # #   expect(query_builder)
        # # end
        #
        # it "adds variable builders to the operation" do
        #   default_val_builder = expect_default_value_builder(
        #     type_klass: "CowType95",
        #     model: "1337"
        #   )
        #
        #   visit_graphql <<-GraphQL
        #     query($cow: CowType95 = 1337, $pig: WatType) {lol}
        #   GraphQL
        #
        #   var_builders = visitor.operations.first.variable_builders
        #   expect(var_builders.length).to eq 2
        #   expect(var_builders["cow"].variable_name).to eq "cow"
        #   expect(var_builders["cow"].type_klass).to eq "CowType95"
        #   expect(var_builders["cow"].default_value_builder).to eq(
        #     default_val_builder
        #   )
        #   expect(var_builders["pig"].variable_name).to eq "pig"
        #   expect(var_builders["pig"].type_klass).to eq "WatType"
        #   expect(var_builders["pig"].default_value).to eq nil
        # end
        #
        # it "adds object-valued variable builders to the operation" do
        #   default_val_builder = expect_default_value_builder(
        #     type_klass: "CowType95",
        #     model: nil
        #   )
        #   expect(default_val_builder).to(receive :add_child_builder!).with(
        #     name: "test",
        #     model: "wat"
        #   )
        #
        #   visit_graphql <<-GraphQL
        #     query($cow: CowType95 = {test: "wat"}) {lol}
        #   GraphQL
        #
        #   var_builders = visitor.operations.first.variable_builders
        #   expect(var_builders.length).to eq 1
        #   expect(var_builders["cow"].variable_name).to eq "cow"
        #   expect(var_builders["cow"].type_klass).to eq "CowType95"
        #   expect(var_builders["cow"].default_value_builder).to eq(
        #     default_val_builder
        #   )
        # end
      end

      context "multiple operations in a single query document" do
        context "without names" do
          it "throws an error" do
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

    context "with variable definitions" do
      it "adds variables definitions to the builder" do
        visit_graphql <<-GraphQL
          query($cow: HeroType) { moo }
        GraphQL

        variable_builders = visitor.operations.first.variable_builders
        expect(variable_builders["cow"].variable_name).to eq "cow"
        expect(variable_builders["cow"].of_type).to eq "HeroType"
      end
    end

  end
end
