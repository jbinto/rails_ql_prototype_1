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
    expect(node).to receive(:resolve_tree_children).and_return([])
    return node
  end

  def node_with_children(children, name: "NodeWithChildren")
    node = make_node name
    expect(node).to receive(:resolve_tree_children).and_return(children)
    return node
  end

  def stub_resolve_lambda(on:)
    allow(on).to receive(:resolve_lambda).and_return(
      ->(args, child_query){{
        args: args,
        child_query: child_query,
        self: self
      }}
    )
  end

  def stub_args(on:, args:)
    expect(on).to receive(:args).and_return(args)
  end

  def stub_empty_args(on:)
    stub_args(on: on, args: {})
  end

  def stub_query(on:, query:)
    expect(on).to receive(:query).and_return(query)
  end

  context "given `products(only_in_stock: true, top: 50) { image { ... }`" do
    it "calls model= on child with result of resolve_lambda" do
      # e.g. { products(only_in_stock: true, top: 50) { image { ... } }}
      image = node_with_no_children name: "Image"
      products = node_with_children [image], name: "Products"
      root = node_with_children [products], name: "Root"

      stub_args on: products, args: { only_in_stock: true, top: 50 }
      stub_query on: products, query: "query_for_products"
      stub_resolve_lambda on: products
      expect(products).to receive(:model=).with({
        args: { only_in_stock: true, top: 50 },
        child_query: "query_for_products",
        self: root
      })

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
end
