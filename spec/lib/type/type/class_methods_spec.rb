require "spec_helper"

describe RailsQL::Type do
  describe "#type_name" do
    it "is a getter/setter" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.type_name "Foo"
      expect(foo_klass.type_name).to eq "Foo"
    end
  end

  describe "#description" do
    it "sets the description" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.description "Lorem ipsum"

      expect(foo_klass.type_definition.description).to eq "Lorem ipsum"
    end
  end

  describe "#anonymous" do
    it "is a getter/setter" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.anonymous true
      expect(foo_klass.anonymous).to eq true
    end
  end

  describe "#kind" do
    it "is a setter" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.kind :scalar
      expect(foo_klass.type_definition.kind).to eq :scalar
    end

    it "raises when called with an unrecognized kind" do
      foo_klass = Class.new RailsQL::Type
      expect{
        foo_klass.kind :spaceship
      }.to raise_error
    end
  end

  describe "#enum_values" do
    it "should add one enum value" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.enum_values :foo

      enum_values = foo_klass.type_definition.enum_values
      expect(enum_values[:foo].name).to eq :foo
    end

    it "should add multiple enum values" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.enum_values :foo, :bar

      enum_values = foo_klass.type_definition.enum_values
      expect(enum_values[:foo].name).to eq :foo
      expect(enum_values[:bar].name).to eq :bar
    end

    it "should add multiple enum values with opts" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.enum_values :foo, :bar, is_deprecated: true

      enum_values = foo_klass.type_definition.enum_values
      expect(enum_values[:foo].is_deprecated).to eq true
      expect(enum_values[:bar].is_deprecated).to eq true
    end

    it "should merge when called multiple times" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.enum_values :foo, :bar
      foo_klass.enum_values :qux

      enum_values = foo_klass.type_definition.enum_values
      expect(enum_values[:foo].name).to eq :foo
      expect(enum_values[:bar].name).to eq :bar
      expect(enum_values[:qux].name).to eq :qux
    end
  end

  describe "#type?" do
    it "should return true by default" do
      foo_klass = Class.new RailsQL::Type
      expect(foo_klass.type?).to eq true
    end
  end

  describe "#type_description" do
    it "returns an OpenStruct with info" do
      foo_klass = Class.new RailsQL::Type
      foo_klass.type_name "Foo"
      expect(foo_klass.type_definition.name).to eq "Foo"
    end
  end

  describe "#valid_child_type?" do
    let(:root_klass) {
      Class.new RailsQL::Type do
        field :foo, data_type: "Integer"
        field :bar, data_type: "Integer"
      end
    }

    it "returns false when the field name does not exist" do
      expect(root_klass.valid_child_type?(
        name: "awesome_beers",
        type_name: "SomeType"  # ???
      )).to eq false
    end

    it "returns false when type is incompatible with the field definition" do
      pending   # XXX: can't figure out how to test this
      fail

      # foo_klass = Class.new RailsQL::Type do
      #   type_name "foo"
      # end
      #
      # expect(RailsQL::Type::KlassFactory).to receive(:find).with(
      #   "FooType"
      # ).and_return foo_klass
      #
      # expect(root_klass.valid_child_type?(
      #   name: "foo",
      #   type_name: "FooType"
      # )).to eq true
    end
  end

  describe "#(get_)initial_query" do
    it "is a getter/setter" do
      foo_klass = Class.new RailsQL::Type do
        initial_query "hello_world"
      end

      expect(foo_klass.get_initial_query).to eq "hello_world"
    end
  end

  describe "#(get_)initial_query" do
    it "is a getter/setter" do
      foo_klass = Class.new RailsQL::Type do
        initial_query "hello_world"
      end

      expect(foo_klass.get_initial_query).to eq "hello_world"
    end
  end

  describe "#field_definitions" do
    it "is a cache/factory for FieldDefinitionCollection" do
      hash = {}
      expect(RailsQL::Field::FieldDefinitionCollection).to receive(:new)
        .once.and_return hash

      foo_klass = Class.new RailsQL::Type
      expect(foo_klass.field_definitions).to eq hash

      # It shouldn't call :new the second time
      expect(foo_klass.field_definitions).to eq hash
    end
  end


  describe "#can" do
    it "adds permissions to the field_definitions" do
      pending
      fail
    end
  end
end
