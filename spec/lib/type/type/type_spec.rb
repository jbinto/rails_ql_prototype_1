require "spec_helper"

describe RailsQL::Type do
  def new_type(
    aliased_as: "top10",
    args_type: (instance_double RailsQL::Type),
    **rest
  )
    opts = {
      aliased_as: aliased_as,
      args_type: args_type
    }.merge(rest)
    described_class.new opts
  end

  def fake_type
    instance_double RailsQL::Type
  end

  def object_klass
    Class.new RailsQL::Type
  end

  def string_klass
    Class.new RailsQL::Type do
      kind :scalar
    end
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

    it "sets with result of parse_value! instance method" do
      foo_klass = Class.new RailsQL::Type do
        def parse_value!(value)
          value.upcase
        end
      end

      type = foo_klass.new aliased_as: "foo", args_type: fake_type
      type.model = "should_become_uppercase"

      expect(type.model).to eq("SHOULD_BECOME_UPPERCASE")
    end
  end

  describe "#type_name" do
    it "does not explode when accessed" do
      type = new_type
      type.type_name
    end
  end

  describe "#initial_query" do
    context "when type class sets initial_query lambda" do
      it "returns the result of the lambda" do
        foo_klass = Class.new RailsQL::Type do
          initial_query ->{"foo_initial_query"}
        end
        foo = foo_klass.new aliased_as: "foo", args_type: fake_type
        expect(foo.initial_query).to eq("foo_initial_query")
      end
    end

    context "when type class has no initial_query call" do
      it "returns nil" do
        foo_klass = Class.new RailsQL::Type
        foo = foo_klass.new aliased_as: "foo", args_type: fake_type
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
    it "delegates to self.class.can?" do
      foo_klass = Class.new RailsQL::Type
      foo = foo_klass.new aliased_as: "foo", args_type: fake_type

      # stub out call to class method
      expect(foo_klass).to receive(:can?).with(:query, "bar", on: foo)
        .and_return(true)

      result = foo.can?(:query, "bar")
      expect(result).to eq true
    end
  end

  describe "#as_json" do
    context "when it is a scalar" do
      it "should return #model untouched" do
        string = string_klass.new(
          aliased_as: "string",
          args_type: fake_type
        )

        string.model = "lazers"
        expect(string.as_json).to eq "lazers"
      end
    end

    context "when it is an object that has scalar fields" do
      it "calls as_json on the scalars" do
        hello = string_klass.new(
          aliased_as: "hello",
          args_type: fake_type
        )
        world = string_klass.new(
          aliased_as: "world",
          args_type: fake_type
        )
        hello.model = "bonjour"
        world.model = "monde"

        object = object_klass.new(
          aliased_as: "object",
          args_type: fake_type,
          field_types: {
            "hello" => hello,
            "world" => world
          }
        )

        expect(object.as_json).to eq({
          "hello" => "bonjour",
          "world" => "monde"
        })
      end
    end

    context "when it is an object that has #omit_from_json? => true" do
      it "returns json untouched" do
        omitted_klass = Class.new RailsQL::Type do
          def omit_from_json?
            true
          end
        end
        hello = string_klass.new aliased_as: "hello", args_type: fake_type
        hello.model = "bonjour"
        omitted = omitted_klass.new(
          aliased_as: "omitted",
          args_type: fake_type
        )
        root = object_klass.new(
          aliased_as: "root",
          args_type: fake_type,
          field_types: { "omitted" => omitted, "hello" => hello }
        )

        expect(root.as_json).to eq({
          "hello" => "bonjour"
        })
      end
    end

    context "when it is an object that has object fields" do
      it "recursively calls as_json on objects until it reaches a scalar" do
        # e.g. { products { hats { images { url }}}}
        def new_string_klass(name)
          string_klass.new(aliased_as: name, args_type: fake_type)
        end

        def new_object_klass(name, field_types: {})
          object_klass.new(
            aliased_as: name,
            args_type: fake_type,
            field_types: field_types
          )
        end

        url = new_string_klass "url"
        images = new_object_klass "images", field_types: { "url" => url }
        hats = new_object_klass "hats", field_types: { "images" => images }
        products = new_object_klass "products", field_types: { "hats" => hats }

        pending
        fail


      end
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
        empty_lambda = ->(){}
        field_definition = instance_double RailsQL::Field::FieldDefinition,
          query_lambda: empty_lambda

        type = new_type field_definition: field_definition
        expect(type.query_lambda).to eq empty_lambda
      end
    end

    describe "#resolve_lambda" do
      it "calls FieldDefinition#resolve" do
        empty_lambda = ->(){}
        field_definition = instance_double RailsQL::Field::FieldDefinition,
          resolve_lambda: empty_lambda

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
