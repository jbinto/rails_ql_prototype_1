# require "spec_helper"
#
# describe RailsQL::Builder::TypeBuilderCollection do
#   describe "#create_and_add_builder!" do
#     before :each do
#       pending "The implementations of these tests are all out of date."
#       fail
#       allow(@builder).to receive(:type_klass).and_return @mocked_type
#       @field_definition = instance_double RailsQL::Field::FieldDefinition
#       allow(@field_definition).to receive(:type).and_return "mocked_type"
#       allow(@field_definition).to receive(:child_ctx).and_return({})
#       allow(@mocked_type).to receive(:field_definitions).and_return(
#         'child_type' => @field_definition
#       )
#     end
#
#     context "when fields exists" do
#       it "intantiates the child builder and adds to builder#child_builders" do
#         child_builder = @builder.add_child_builder "child_type"
#
#         expect(@builder.child_builders['child_type']).to eq child_builder
#         expect(child_builder.class).to eq RailsQL::Type::Builder
#         expect(child_builder.type_klass).to eq MockedType
#         expect(child_builder.instance_variable_get("@root")).to eq false
#         expect(child_builder.instance_variable_get("@ctx")).to eq({})
#       end
#
#       it "merges child_ctx with ctx and passes down to children" do
#         expect(@field_definition).to receive(:child_ctx).and_return(
#           mega_lasers: :very_yes
#         )
#
#         child_builder = @builder.add_child_builder "child_type"
#         ctx = child_builder.instance_variable_get(:@ctx)
#
#         expect(ctx[:mega_lasers]).to eq :very_yes
#       end
#
#       it "is idempotent" do
#         child_builder = @builder.add_child_builder "child_type"
#
#         expect(@builder.add_child_builder('child_type')).to eq child_builder
#       end
#     end
#
#     context "when association field does not exist" do
#       it "raises invalid field error" do
#         expect{@builder.add_child_builder 'invalid_type'}.to raise_error
#       end
#     end
#   end
#
#   describe "#add_existing_builder!" do
#     pending "dev time for fragments"
#     fail
#   end
#
#   describe "#build_types!" do
#     context "when each type builder's name matches a field definition" do
#       it "returns a hash of type instances based on the field definitions" do
#       end
#     end
#
#     context "when a type builder's name does not match any field definitions" do
#       it "raises an error" do
#       end
#     end
#   end
#
# end
