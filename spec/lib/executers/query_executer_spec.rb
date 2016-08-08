require "spec_helper"

describe RailsQL::Executers::QueryExecuter do
  def run_query_executer_test(root:, operation_type: :query)
    described_class.new(
      root: root,
      operation_type: operation_type
    ).execute!
  end

  describe '#execute!' do
    def make_node(name)
      instance_double RailsQL::Type, name
    end

    def node_with_no_children(name: "NodeWithNoChildren")
      node = make_node name
      expect(node).to receive(:query_tree_children).and_return([])
      return node
    end

    def node_with_children(children, name: "NodeWithChildren")
      node = make_node name
      expect(node).to receive(:query_tree_children).and_return(children)
      return node
    end

    def expect_initial_query(on:, with:)
      expect(on).to receive(:initial_query).and_return with
      expect(on).to receive(:query=).with(with)
    end

    def ignore_query_lambda(on:)
      allow(on).to receive(:query_lambda).and_return nil
    end

    def ignore_initial_query(on:)
      allow(on).to receive(:initial_query).and_return "initial_query"
      allow(on).to receive(:query=).with "initial_query"
    end

    def ignore_args(on:)
      allow(on).to receive(:args).and_return({})
    end

    context "initial query" do
      it "sets initial query on root" do
        # e.g. { root }
        root = node_with_no_children name: "Root"

        expect(root).to receive(:initial_query).and_return nil
        expect(root).to receive(:query=).with(nil)

        # tangential to this test
        ignore_query_lambda(on: root)

        run_query_executer_test(root: root)
      end

      it "sets initial query on children one-level deep" do
        # e.g. { root { field_1 }}
        field_1 = node_with_no_children name: "Field_1"
        root = node_with_children([field_1])

        expect_initial_query(on: root, with: nil)
        expect_initial_query(on: field_1, with: "Moo.all")

        # tangential to this test
        ignore_query_lambda(on: root)
        ignore_query_lambda(on: field_1)

        run_query_executer_test(root: root)
      end

      it "sets initial query on children two-levels deep" do
        # e.g. { root { field_1 { field_1_a }}}
        field_1_a = node_with_no_children name: "Field_1_a"
        field_1 = node_with_children [field_1_a], name: "Field_1"
        root = node_with_children [field_1], name: "Root"

        expect_initial_query(on: root, with: nil)
        expect_initial_query(on: field_1, with: "Field_1.all")
        expect_initial_query(on: field_1_a, with: "Field_1_a.all")

        # tangential to this test
        ignore_query_lambda(on: root)
        ignore_query_lambda(on: field_1)
        ignore_query_lambda(on: field_1_a)

        run_query_executer_test(root: root)
      end
    end

    context "execution of lambda" do
      def stub_query_lambda(on:, name:)
        allow(on).to receive(:query_lambda).and_return(
          ->(args, child_query){{
            name: "#{name}_query_lambda",
            args: args,
            child_query: child_query,
            self: self
          }}
        )
      end

      def stub_query_lambda_with_nil(on:)
        expect(on).to receive(:query_lambda).and_return nil
      end

      def stub_query_var(on:, query:)
        expect(on).to receive(:query).and_return(query)
      end

      it "executes query_lambda in the context of its parent" do
        # e.g. { root { drinks { beers }}
        # The query lambda defined on `beers` executes in `drink`s context.
        # The query lambda defined on `drinks` executes in `root`s context.
        # No query lambda should ever be defined on a root.

        beers = node_with_no_children name: "Beers"
        drinks = node_with_children [beers], name: "Drinks"
        root = node_with_children [drinks], name: "Root"

        # XXX TODO: for now, stubbed types just return canned args
        # this would be for e.g. { root { drinks(promos: true) { beers }}}
        ignore_args(on: beers)
        ignore_args(on: drinks)

        # use a canned query_lambda on every type that just returns
        # info about how it was called.
        stub_query_lambda(on: beers, name: "beers")
        stub_query_lambda(on: drinks, name: "drinks")
        stub_query_lambda_with_nil(on: root)

        # e.g. the initial_query of each type
        #  (note: since we're stubbing we can't just set #initial_query,
        #  we have to do it a bit awkwardly)
        stub_query_var(on: beers, query: "Beers.all")
        stub_query_var(on: drinks, query: "Drinks.all")

        # omg an actual assertion!
        expect(drinks).to receive(:query=).with({
          name: "beers_query_lambda",
          args: {},
          child_query: "Beers.all",
          self: drinks
        })

        expect(root).to receive(:query=).with({
          name: "drinks_query_lambda",
          args: {},
          child_query: "Drinks.all",
          self: root
        })

        # tangential to this test
        ignore_initial_query(on: root)
        ignore_initial_query(on: drinks)
        ignore_initial_query(on: beers)

        run_query_executer_test(root: root)
      end

      it "passes correct args to query_lambda" do
        # e.g. { root { heroes(super: true, since: 1970) }}
        heroes = node_with_no_children name: "Hero"
        root = node_with_children [heroes], name: "Root"

        stub_query_lambda(on: heroes, name: "heroes")
        stub_query_lambda_with_nil(on: root)

        stub_query_var(on: heroes, query: "Heroes.all")

        allow(heroes).to receive(:args).and_return({
          super: true,
          since: 1970,
        })

        # don't worry about any other fields e.g. child_query
        # just concerned with args here
        expect(root).to receive(:query=).with hash_including({
          args: {
            super: true,
            since: 1970
          }
        })

        # tangential to this test
        ignore_initial_query(on: root)
        ignore_initial_query(on: heroes)

        run_query_executer_test(root: root)
      end

    end
  end

end
