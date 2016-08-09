require "spec_helper"

describe RailsQL::Type do
  def new_type(aliased_as: "top10", args_type: nil, **rest)
    opts = {
      aliased_as: aliased_as,
      args_type: args_type
    }.merge(rest)
    described_class.new opts
  end

  describe "#new" do
    it "constructs an object" do
      type = new_type
    end
  end

  describe "#model=" do
    it "is a setter" do
      type = new_type
      type.model = "foo"
      expect(type.model).to eq "foo"
    end

    it "does something with parse_value!" do
      # TODO: see type instances, they override this
      pending
      fail
    end
  end

  describe "#type_name" do
    it "fails" do
      # TODO: test that type_name delegates
      pending
      type = new_type
      type.type_name   # XXX fails
    end
  end

  describe "#initial_query" do
    context "when type class sets initial_query lambda" do
      it "returns the result of the lambda" do
        Foo = Class.new RailsQL::Type do
          initial_query ->{"foo_initial_query"}
        end
        foo = Foo.new aliased_as: "foo", args_type: nil
        expect(foo.initial_query).to eq("foo_initial_query")
      end
    end

    context "when type class has no initial_query call" do
      it "returns nil" do
        Foo = Class.new RailsQL::Type
        foo = Foo.new aliased_as: "foo", args_type: nil
        expect(foo.initial_query).to eq nil
      end
    end
  end

  describe "#omit_from_json?" do
    it "should be false" do
      expect(new_type.omit_from_json?).to eq false
    end
  end

  describe "#root?" do
    it "should default to false" do
      type = new_type
      expect(type.root?).to eq false
    end

    it "should return what was specified in constructor kwarg `root`" do
      type = new_type root: true
      expect(type.root?).to eq true
    end
  end

  describe "#can?" do
    it "should xxx" do
      # undefined local variable or method `field_definitions' for #<RailsQL::Type:0x007f861c68b3f8>
      pending
      fail

      type = new_type
      type.can?(:query, "foo")
    end
  end

  describe "#as_json" do
    it "should xxx" do
      type = new_type
      type.as_json
    end
  end



  context "methods delegated to FieldDefinition" do
    describe "#field_or_arg_name" do
      it "calls FieldDefinition#name" do
        field_definition = instance_double RailsQL::Field::FieldDefinition,
          name: "foo"

        type = new_type field_definition: field_definition
        expect(type.field_or_arg_name).to eq("foo")
      end
    end

    describe "#query_lambda" do
      it "calls FieldDefinition#query_lambda" do
        pending
        fail

        empty_lambda = ->(){}
        field_definition = instance_double RailsQL::Field::FieldDefinition,
          query_lambda: empty_lambda

        type = new_type field_definition: field_definition

        # FAIL:
        # the RailsQL::Field::FieldDefinition class does not implement the instance method: query_lambda
        expect(type.query_lambda).to eq empty_lambda
      end
    end

    describe "#resolve_lambda" do
      it "calls FieldDefinition#resolve" do
        empty_lambda = ->(){}
        field_definition = instance_double RailsQL::Field::FieldDefinition,
          resolve: empty_lambda

        type = new_type field_definition: field_definition
        expect(type.resolve_lambda).to eq empty_lambda
      end
    end
  end

  context "methods delegated to args_type" do
    describe "#args" do
      it "should call args_type.as_json" do
        hash = {a: 1, b: 2}
        args_type = instance_double RailsQL::Type,
          as_json: hash

        type = new_type args_type: args_type
        expect(type.args).to eq hash
      end

      it "should not explode when args_type is empty" do
        type = new_type
        expect(type.args).to eq nil
      end
    end
  end

  context "methods delegated to field_types" do
    describe "#query_tree_children" do
      it "returns @field_types.values" do
        child1 = new_type
        child2 = new_type
        field_types = { child1: child1, child2: child2 }

        type = new_type field_types: field_types

        expect(type.query_tree_children).to eq(
          [child1, child2]
        )
      end
    end

    describe "#resolve_tree_children" do
      # XXX: really exactly the same as #query_tree_children?
      it "returns @field_types.values" do
        child1 = new_type
        child2 = new_type
        field_types = { child1: child1, child2: child2 }

        type = new_type field_types: field_types

        expect(type.resolve_tree_children).to eq(
          [child1, child2]
        )
      end
    end
  end


end



#   describe "#build_query!" do
#     context "when it has no fields" do
#       it "returns the initial query" do
#         allow(type_klass).to receive(:get_initial_query).and_return(
#           ->{:best_query_ever}
#         )
#         expect(type_klass.new.build_query!).to eq :best_query_ever
#       end
#     end
#
#     context "when it has fields" do
#       it "calls Field#appended_parent_query and saves results to query" do
#         field = instance_double RailsQL::Field::Field
#         type = type_klass.new
#         allow(type).to receive(:fields).and_return(fake_field: field)
#         child_type = instance_double described_class
#         allow(field).to receive(:prototype_type).and_return(
#           child_type
#         )
#         allow(child_type).to receive :build_query!
#         allow(type_klass).to receive(:get_initial_query).and_return double
#
#         expect(field).to receive(:appended_parent_query).and_return :lions
#         type.build_query!
#         expect(type.query).to eq :lions
#       end
#
#       it "reduces over multiple fields via Field#appended_parent_query" do
#         fields = {
#           fake_field_1: instance_double(RailsQL::Field::Field),
#           fake_field_2: instance_double(RailsQL::Field::Field)
#         }
#         allow(type_klass).to receive(:get_initial_query).and_return(
#           -> {"the cow says"}
#         )
#         type = type_klass.new
#         allow(type).to receive(:fields).and_return fields
#
#         fields.each do |k, field|
#           allow(field).to(
#             receive_message_chain(:prototype_type, :build_query!).and_return(
#               double
#             )
#           )
#           expect(field).to receive(:appended_parent_query) do
#             type.query + " moo"
#           end.once
#         end
#         expect(type.build_query!).to eq "the cow says moo moo"
#       end
#     end
#   end
#
#   describe "#resolve_child_types!" do
#     before :each do
#       @type = type_klass.new
#       @field = instance_double RailsQL::Field::Field
#       allow(@type).to receive(:fields).and_return(fake_field: @field)
#       allow(@field).to receive :parent_type=
#       allow(@field).to receive :resolve_models_and_dup_type!
#       allow(@field).to receive(:types).and_return []
#     end
#
#     it "assigns self as the parent_type to each field" do
#       expect(@field).to receive(:parent_type=).with @type
#
#       @type.resolve_child_types!
#     end
#
#     it "calls Field#resolve_models_and_dup_type! for each field" do
#       expect(@field).to receive :resolve_models_and_dup_type!
#       @type.resolve_child_types!
#     end
#
#     it "calls resolve_child_types! on child_types" do
#       field_type = instance_double described_class
#       allow(@field).to receive(:types).and_return [field_type]
#
#       expect(field_type).to receive :resolve_child_types!
#
#
#       @type.resolve_child_types!
#     end
#
#     it "runs resolve callbacks" do
#       expect do |b|
#         type_klass.before_resolve &b
#         @type.resolve_child_types!
#       end.to yield_control
#     end
#
#   end
#
#   describe "#as_json" do
#     context "when kind is defaulted to :OBJECT" do
#       it "reduces over #as_json on fields" do
#         field = instance_double RailsQL::Field::Field
#         allow(field).to receive(:singular?).and_return true
#         type = type_klass.new
#         allow(type).to receive(:fields).and_return(
#           fake_field_1: field,
#           fake_field_2: field
#         )
#         allow(field).to receive_message_chain(:types, :as_json).and_return(
#           ["hello" => "world"]
#         )
#
#         expect(type.as_json).to eq(
#           "fake_field_1" => {"hello" => "world"},
#           "fake_field_2" => {"hello" => "world"}
#         )
#       end
#     end
#
#   end
# end
