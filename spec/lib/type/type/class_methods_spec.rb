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



  # let(:type_klass) {Class.new described_class}
  #
  # describe ".field" do
  #   context "when a type option is passed" do
  #     it "adds a FieldDefinition" do
  #       child_type = instance_double described_class
  #       field_def_klass = class_double("RailsQL::Field::FieldDefinition")
  #         .as_stubbed_const
  #       field_definition = double
  #
  #       expect(field_def_klass).to receive(:new).with(:added_field,
  #         type: child_type
  #       ).and_return field_definition
  #
  #       type_klass.field :added_field, type: child_type
  #
  #       expect(type_klass.field_definitions[:added_field]).to eq(
  #         field_definition
  #       )
  #     end
  #   end
  #
  #   context "when name is prefixed by double underscores" do
  #     it "raises an error" do
  #       expect{
  #         type_klass.field(:__field_name,
  #           type: double
  #         )
  #       }.to raise_error
  #     end
  #   end
  #
  #   context "when name is reserved" do
  #     it "raises an error" do
  #       expect{
  #         type_klass.field(:query,
  #           type: double
  #         )
  #       }.to raise_error
  #     end
  #   end
  #
  #   context "when a name is defined on the Type subclass" do
  #     it "does not raise an error" do
  #       type_klass.class_eval do
  #         def example_field
  #         end
  #       end
  #
  #       expect{
  #         type_klass.field(:example_field,
  #           type: double
  #         )
  #       }.to_not raise_error
  #     end
  #   end
  # end
  #
  # describe ".kind" do
  #   context "when passed a valid kind symbol" do
  #     it "sets the kind" do
  #       type_klass.kind :OBJECT
  #
  #       results = type_klass.type_definition.kind
  #
  #       expect(results).to eq :OBJECT
  #     end
  #   end
  #
  #   context "when passed an invalid kind" do
  #     it "raises an error" do
  #       expect{type_klass.kind(:MEGA_SHARK)}.to raise_error
  #     end
  #   end
  #
  #   context "when kind is not set" do
  #     context "without args" do
  #       it "returns the OBJECT kind" do
  #         results = type_klass.type_definition.kind
  #
  #         expect(results).to eq :OBJECT
  #       end
  #     end
  #   end
  # end
  #
  # shared_examples "type_association" do |method_sym, singular|
  #   it "aliases .field" do
  #     field_def_klass = class_double("RailsQL::Field::FieldDefinition")
  #       .as_stubbed_const
  #     field_definition = double
  #     expect(field_def_klass).to receive(:new).with(:cows_and_stuff,
  #       type: :reasons,
  #       singular: singular
  #     ).and_return field_definition
  #     type_klass.send method_sym, :cows_and_stuff, type: :reasons
  #   end
  # end
  # #
  # # describe ".has_many" do
  # #   it_behaves_like "type_association", :has_many, false
  # # end
  # #
  # # describe ".has_one" do
  # #   it_behaves_like "type_association", :has_one, true
  # # end
  #
end
