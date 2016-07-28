def expect_directive_builder(type_klass:, on:)
  directive_builder = instance_double RailsQL::Builder::DirectiveBuilder
  expect(RailsQL::Builder::DirectiveBuilder).to receive(:new).with(
    type_klass: type_klass
  ).and_return directive_builder
  # XXX this should not be the same typebuilder for operations!
  expect(on).to receive(:add_directive_builder!).with(
    directive_builder
  )
  allow(directive_builder).to receive(:arg_builder)
  return directive_builder
end

def expect_inline_fragment(name: "moo", field_alias: nil)
  @fragment_builder = instance_double "RailsQL::Builder::FragmentBuilder"
  type_builder = instance_double "RailsQL::Builder::FragmentBuilder"

  expect(RailsQL::Builder::FragmentBuilder).to receive(:new)
    .and_return @fragment_builder
  expect(query_root_builder).to receive(:add_fragment_builder!).with(
    @fragment_builder
  ).and_return @fragment_builder
  expect(@fragment_builder).to receive(:add_child_builder!).with(
    name: name,
    field_alias: field_alias
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
