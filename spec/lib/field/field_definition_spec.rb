require "spec_helper"

describe RailsQL::Field::FieldDefinition do
  describe "#initialize" do
    {
      args: :hash,
      child_ctx: :hash,
      resolve: :lambda,
      query: :lambda
    }.each do |opt_name, type|
      it "throws an error if :#{opt_name} is not a #{type}" do
        type_object = instance_double RailsQL::Type
        expect{
          described_class.new "things", type: type_object, opt_name => "dinosaur"
        }.to raise_error(RuntimeError, /must be/)
      end
    end
  end

  describe "#type_klass" do
    it "uses the klass factory to find the class by name" do
      field = described_class.new "villian", type: "Character"
      expect(RailsQL::Type::KlassFactory).to receive(:find).with("Character")

      field.type_klass
    end
  end

  describe "#args_klass" do
    it "returns an anonymous input object if no :args_klass lambda is provided" do
      pending
      fail

      villian_type = instance_double RailsQL::Type
      input_object = class_double RailsQL::Type::AnonymousInputObject
      field = described_class.new "villian"

      expect(field).to(
        receive(:type_klass).and_return villian_type
      )
      expect(Class).to(
        receive(:new).with(RailsQL::Type::AnonymousInputObject).and_return(
          input_object
        )
      )
      expect(field.args_type_klass).to eq input_object
    end

    it <<-END_IT.strip_heredoc do
      evaluates the :args lambda passed to the initializer in the context of
      the type passing it the anonymous input object as an argument
    END_IT
      pending
      fail

      villian_type = instance_double RailsQL::Type
      input_object = class_double RailsQL::Type::AnonymousInputObject
      args_lambda = ->(args){:input_object_would_go_here}
      field = described_class.new "villian", args: args_lambda

      expect(field).to(
        receive(:type_klass).and_return villian_type
      )
      expect(Class).to(
        receive(:new).with(RailsQL::Type::AnonymousInputObject).and_return(
          input_object
        )
      )
      expect(field.args_type_klass).to eq :input_object_would_go_here
    end
  end

  describe "#add_permission!" do
    context "for a valid operation" do
      it "appends the permissions to #permissions[operation]" do
        field = described_class.new "villian", type: :String
        true_lambda = ->(){true}
        field.add_permission!(:query, true_lambda)

        # XXX TODO: why is `permissions[:query]` an array?
        expect(field.permissions[:query]).to eq([true_lambda])
      end
    end

    context "for an invalid operation" do
      it "raises an error" do
        field = described_class.new "villian", type: :String
        expect{
          field.add_permission!(:delete, ->(){true})
        }.to raise_error(RuntimeError, /Cannot add delete to villian/)

      end
    end
  end
end

  # XXX: #append_to_query removed

  # describe "#append_to_query" do
  #   context "when field_definition has a query defined" do
  #     it <<-END_IT.strip_heredoc do
  #       instance execs the field_definition#query in the context of the parent
  #       data type
  #     END_IT
  #       type = instance_double RailsQL::Type
  #       args = {}
  #       query = double
  #
  #       field_definition_query = ->(actual_args, actual_query){
  #         # e.g. [args, query, type]
  #         [actual_args, actual_query, self]
  #       }
  #       field_definition = described_class.new("stuff",
  #         query: field_definition_query
  #       )
  #
  #       expect(field_definition.append_to_query(
  #         parent_type: type,
  #         args: args,
  #         child_query: query
  #       )).to eq [args, query, type]
  #     end
  #   end
  #
  #   context "when field_definition does not have a query defined" do
  #     it "returns the parent_query untouched" do
  #       type = instance_double RailsQL::Type
  #       expect(type).to receive(:query).and_return "parent_query_goes_here"
  #       field_definition = described_class.new "stuff", query: nil
  #
  #       expect(field_definition.append_to_query(
  #         parent_type: type,
  #         args: double,
  #         child_query: double
  #       )).to eq "parent_query_goes_here"
  #     end
  #   end
  # end

  # XXX: these tests refer to `parent_type` which is gone?

  # describe "#resolve_lambda" do
  #   context "when field_definition has a resolve_lambda defined" do
  #     it <<-END_IT.strip_heredoc do
  #       instance execs the field_definition#resolve_lambda in the context of the
  #       parent data type
  #     END_IT
  #       type = instance_double RailsQL::Type
  #       args = {}
  #       query = double
  #
  #       resolve_lambda = ->(actual_args, actual_query){
  #         [actual_args, actual_query, self]
  #       }
  #       field_definition = described_class.new("stuff",
  #         resolve_lambda: resolve_lambda
  #       )
  #
  #       expect(field_definition.resolve_lambda(
  #         parent_type: type,
  #         args: args,
  #         child_query: query
  #       )).to eq [args, query, type]
  #     end
  #   end
  #
  #   context "when field_definition does not have a resolve defined" do
  #     context "when parent_type has the field name defined as a method" do
  #       it "returns parent_type#field_name" do
  #         type = instance_double RailsQL::Type
  #         # don't use stubs because base does not define field_name
  #         type.instance_eval do
  #           def stuff
  #             "parent_model_stuff_field"
  #           end
  #         end
  #         field_definition = described_class.new "stuff", resolve_lambda: nil
  #
  #         expect(field_definition.resolve_lambda(
  #           parent_type: type,
  #           args: double,
  #           child_query: double
  #         )).to eq "parent_model_stuff_field"
  #       end
  #     end
  #
  #     context "when parent_type does not respond to field name" do
  #       it "returns parent_type.model#field_name" do
  #         parent_model = double
  #         expect(parent_model).to receive(:stuff).and_return(
  #           "parent_model_stuff_field"
  #         )
  #         type = instance_double RailsQL::Type
  #         # XXX: twice because `respond_to?` is considered "receiving"
  #         # expect(type).to receive(:model).twice.and_return parent_model
  #         allow(type).to receive(:model).and_return parent_model
  #         field_definition = described_class.new "stuff", resolve_lambda: nil
  #
  #         expect(field_definition.resolve_lambda(
  #           parent_type: type,
  #           args: double,
  #           child_query: double
  #         )).to eq "parent_model_stuff_field"
  #       end
  #     end
  #
  #     context "when parent_type.model does not respond to field name" do
  #       it "raises an error" do
  #         type = instance_double RailsQL::Type
  #         parent_model = double
  #         allow(type).to receive(:model).and_return parent_model
  #
  #         field_definition = described_class.new "field_not_on_model", resolve_lambda: nil
  #
  #         expect {
  #           field_definition.resolve_lambda(
  #             parent_type: type,
  #             args: double,
  #             child_query: double
  #           )
  #         }.to raise_error(RailsQL::NullResolve)
  #       end
  #     end
  #   end
  # end
