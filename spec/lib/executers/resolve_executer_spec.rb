require "spec_helper"

describe RailsQL::Executers::ResolveExecuter do
  def run_resolve_executer_test(root:, operation_type: :query)
    described_class.new(
      root: root,
      operation_type: operation_type
    ).execute!
  end

  def make_node(name)
    instance_double RailsQL::Type, name
  end

  def node_with_no_children(name: "NodeWithNoChildren")
    node = make_node name
    allow(node).to receive(:resolve_tree_children).and_return([])
    return node
  end

  def node_with_children(children, name: "NodeWithChildren")
    node = make_node name
    allow(node).to receive(:resolve_tree_children).and_return(children)
    return node
  end

  # This lambda just returns a canned response of the args it was called
  # with and the current context of `self`.
  def stub_resolve_lambda(on:)
    allow(on).to receive(:resolve_lambda).and_return(
      ->(args, child_query){{
        args: args,
        child_query: child_query,
        self: self
      }}
    )
  end

  def stub_empty_resolve_lambda(on:)
    allow(on).to receive(:resolve_lambda).and_return nil
  end

  def stub_args(on:, args:)
    allow(on).to receive(:args).and_return(args)
  end

  def stub_empty_args(on:)
    stub_args(on: on, args: {})
  end

  def stub_query(on:, query:)
    allow(on).to receive(:query).and_return(query)
  end

  context "given `products(only_in_stock: true, top: 50) { image { ... }`" do
    it "calls model= on child with result of resolve_lambda" do
      # e.g. { products(only_in_stock: true, top: 50) { upc, image { ... } }}
      image = node_with_no_children name: "Image"
      upc = node_with_no_children name: "UPC"
      products = node_with_children [upc, image], name: "Products"
      root = node_with_children [products], name: "Root"

      # Ensure that resolve_lambda is called with correct args,
      # child_query, and self reference.
      stub_args on: products, args: { only_in_stock: true, top: 50 }
      stub_query on: products, query: "query_for_products"
      stub_resolve_lambda on: products
      expect(products).to receive(:model=).with({
        args: { only_in_stock: true, top: 50 },
        child_query: "query_for_products",
        self: root
      })

      # It should recurse the tree downwards...
      stub_empty_args on: upc
      stub_query on: upc, query: "query_for_upc"
      stub_resolve_lambda on: upc
      expect(upc).to receive(:model=).with({
        args: {},
        child_query: "query_for_upc",
        self: products
      })

      # ..and should also walk the tree side-to-side.
      stub_empty_args on: image
      stub_query on: image, query: "query_for_image"
      stub_resolve_lambda on: image
      expect(image).to receive(:model=).with({
        args: {},
        child_query: "query_for_image",
        self: products
      })

      run_resolve_executer_test(root: root)
    end
  end

  context "when there is no resolve lambda" do
    context "and there is no default implementation" do
      it "raises an error" do
        # Mock: Scalar field `url`
        url = node_with_no_children name: "URL"
        stub_empty_args on: url
        stub_query on: url, query: "query_for_url"
        stub_empty_resolve_lambda on: url
        expect(url).to receive(:field_or_arg_name).and_return "url"

        # Mock: Normal Root object (i.e. with no #url method)
        root = node_with_children [url], name: "Root"
        allow(root).to receive(:model)

        expect{
          run_resolve_executer_test(root: root)
        }.to raise_error /does not have an explicit resolve/
      end
    end

    context "parent type responds_to $FIELD_NAME" do
      it "resolves using that method" do
        # Mock: Scalar field `url`
        url = node_with_no_children name: "URL"
        stub_empty_args on: url
        stub_query on: url, query: "query_for_url"
        stub_empty_resolve_lambda on: url
        expect(url).to receive(:field_or_arg_name).and_return "url"

        # Mock: Root object that has #url method
        #   (Note: Due to verifying doubles, need to subclass in order to
        #   not have RSpec warn about #url not existing on RailsQL::Type)
        root_klass = Class.new RailsQL::Type do
          def url
          end
        end
        root = instance_double root_klass, "Root"
        allow(root).to receive(:resolve_tree_children).and_return([url])
        allow(root).to receive(:url).and_return "http://google.com"

        # The ResolveExecuter should set #model= on the URL type with
        # the result of the call to Root#url.
        allow(url).to receive(:model=).with "http://google.com"
        run_resolve_executer_test(root: root)
      end
    end

    context "parent type's model responds_to $FIELD_NAME" do
      it "resolves using that method" do
        # Mock: Scalar field `url`
        url = node_with_no_children name: "URL"
        stub_empty_args on: url
        stub_query on: url, query: "query_for_url"
        stub_empty_resolve_lambda on: url
        expect(url).to receive(:field_or_arg_name).and_return "url"

        # Mock: Root object that has #model.url method
        root = node_with_children [url], name: "Root"
        allow(root).to receive_message_chain(
          :model,
          :url
        ).and_return "http://example.org"

        # The ResolveExecuter should set #model= on the URL type with
        # the result of the call to Root#url.
        allow(url).to receive(:model=).with "http://example.org"
        run_resolve_executer_test(root: root)
      end
    end
  end
end
