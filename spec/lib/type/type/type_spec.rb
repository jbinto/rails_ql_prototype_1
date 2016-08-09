require "spec_helper"


describe RailsQL::Type do
  def new_type(aliased_as: "top10", args_type: nil)
    described_class.new aliased_as: aliased_as, args_type: args_type
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
      # not sure what it should do exactly.
      pending
      fail
    end
  end

  describe "#type_name" do
    it "fails" do
      pending
      type = new_type
      type.type_name   # XXX fails
    end
  end

  describe "#field_or_arg_name" do
    it "fails" do
      pending
      type = new_type
      type.field_or_arg_name   # XXX fails
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
