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
        expect{
          described_class.new "things", type: double, opt_name => "dinosaur"
        }.to raise_error
      end
    end

  end

  describe "#read_permission_lambda" do
    context "when permissions have been added" do
      it "returns the list of read permissions" do
        field_definition = described_class.new "stuff", type: double
        permission = double
        field_definition.add_read_permission permission

        expect(field_definition.read_permissions).to eq [permission]
      end
    end

    context "when no permissions have been set" do
      it "returns an array of one lambda which evaluates to false" do
        field_definition = described_class.new "stuff", type: double

        expect(field_definition.read_permissions[0].call).to eq false
      end
    end
  end

  describe "#append_to_query" do
    context "when field_definition has a query defined" do
      it "instance execs the field_definition#query in the context of the parent data type" do
        type = instance_double RailsQL::Type
        args = {}
        query = double

        field_definition_query = ->(actual_args, actual_query){
          [actual_args, actual_query, self]
        }
        field_definition = described_class.new("stuff",
          query: field_definition_query
        )

        expect(field_definition.append_to_query(
          parent_type: type,
          args: args,
          child_query: query
        )).to eq [args, query, type]
      end
    end

    context "when field_definition does not have a query defined" do
      it "returns the parent_query untouched" do
        type = instance_double RailsQL::Type
        expect(type).to receive(:query).and_return "parent_query"
        field_definition = described_class.new "stuff", query: nil

        expect(field_definition.append_to_query(
          parent_type: type,
          args: double,
          child_query: double
        )).to eq "parent_query"
      end
    end
  end

  describe "#resolve" do
    context "when field_definition has a resolve defined" do
      it "instance execs the field_definition#resolve in the context of the parent data type" do
        type = instance_double RailsQL::Type
        args = {}
        query = double

        field_definition_resolve = ->(actual_args, actual_query){
          [actual_args, actual_query, self]
        }
        field_definition = described_class.new("stuff",
          resolve: field_definition_resolve
        )

        expect(field_definition.resolve(
          parent_type: type,
          args: args,
          child_query: query
        )).to eq [args, query, type]
      end
    end

    context "when field_definition does not have a resolve defined" do
      context "when parent_type has the field name defined as a method" do
        it "returns parent_type#field_name" do
          type = instance_double RailsQL::Type
          # don't use stubs because base does not define field_name
          type.instance_eval do
            def stuff
              "parent_model"
            end
          end
          field_definition = described_class.new "stuff", resolve: nil

          expect(field_definition.resolve(
            parent_type: type,
            args: double,
            child_query: double
          )).to eq "parent_model"
        end
      end

      context "when parent_type does not have the field name defined as a method" do
        it "returns parent_type.model#field_name" do
          parent_model = double
          expect(parent_model).to receive(:stuff).and_return(
            "parent_model_field"
          )
          type = instance_double RailsQL::Type
          expect(type).to receive(:model).twice.and_return parent_model
          field_definition = described_class.new "stuff", resolve: nil

          expect(field_definition.resolve(
            parent_type: type,
            args: double,
            child_query: double
          )).to eq "parent_model_field"
        end
      end
    end
  end

  #
  # describe ".can" do
  #   context "when :read" do
  #     context "with :when option" do
  #       context "when the field definition for that field exists" do
  #         it "calls field_definition#add_read_permission with :when option" do
  #           permission = ->{true}
  #           field_definition = type_klass.field_definitions[:example_field]
  #
  #           expect(field_definition).to(
  #             receive(:add_read_permission).with permission
  #           )
  #
  #           type_klass.can(:read,
  #             fields: [:example_field],
  #             when: permission
  #           )
  #         end
  #       end
  #     end
  #
  #     context "when the field definition for that field does not exist" do
  #       it "raises error" do
  #         expect{
  #           type_klass.can(:read,
  #             fields: [:fake_field]
  #           )
  #         }.to raise_error
  #       end
  #     end
  #
  #     context "without :when option" do
  #       it "calls field_definition#add_read_permission with `->{true}`" do
  #         field_definition = type_klass.field_definitions[:example_field]
  #
  #         expect(field_definition).to receive(:add_read_permission) do |lambda|
  #           expect(lambda.call).to eq true
  #         end
  #
  #         type_klass.can :read, fields: [:example_field]
  #       end
  #     end
  #   end
  # end
  #
  # describe "included" do
  #   it "adds after_resolve :authorize_query, if: :root? callback" do
  #     dummy_klass = Class.new
  #     expect(dummy_klass).to receive(:after_resolve).with(
  #       :authorize_query!, if: :root?
  #     )
  #
  #     dummy_klass.include described_class
  #   end
  # end
  #
  # describe "instance methods" do
  #   let(:type) {type_klass.new(field: {})}
  #   let(:field) {instance_double RailsQL::Field::Field}
  #
  #   describe "#unauthorized_query_fields" do
  #     context "when there are unauthorized fields" do
  #       it "returns a hash in the form {field_name => true}" do
  #         field_2 = instance_double RailsQL::Field::Field
  #         allow(type).to receive(:fields).and_return(
  #           stuff: field,
  #           other_stuff: field_2
  #         )
  #
  #         allow(field).to receive(:has_read_permission?).and_return false
  #         allow(field_2).to receive(:has_read_permission?).and_return true
  #         type.fields.each do |k, field|
  #           allow(field).to(
  #             receive_message_chain(:types, :first, :unauthorized_query_fields)
  #               .and_return HashWithIndifferentAccess.new
  #           )
  #         end
  #
  #         unauthorized_query_fields = type.unauthorized_query_fields
  #
  #         expect(unauthorized_query_fields).to eq("stuff" => true)
  #       end
  #     end
  #
  #     context "when there are nested unauthorized fields" do
  #       it "returns a nested hash" do
  #         allow(type).to receive(:fields).and_return stuff: field
  #
  #         allow(field).to receive(:has_read_permission?).and_return true
  #         allow(field).to(
  #           receive_message_chain(:types, :first, :unauthorized_query_fields)
  #             .and_return(things: true)
  #         )
  #
  #         expect(type.unauthorized_query_fields).to eq(
  #           "stuff" => {"things" => true}
  #         )
  #       end
  #     end
  #
  #   end
  #
  #   describe "#authorize_query!" do
  #     context "when unauthorized_query_fields is not empty" do
  #       it "raises UnauthorizedQuery error" do
  #         allow(type).to receive(:unauthorized_query_fields).and_return(
  #           example_field: true
  #         )
  #
  #         expect{type.authorize_query!}.to raise_error
  #       end
  #     end
  #
  #     context "when unauthorized_query_fields is empty" do
  #       it "does not raise an error" do
  #         allow(type).to receive(:unauthorized_query_fields).and_return(
  #           HashWithIndifferentAccess.new
  #         )
  #
  #         expect{type.authorize_query!}.not_to raise_error
  #       end
  #     end
  #   end
  #
  #   describe "#authorize_mutation!" do
  #     pending "mutations"
  #     skip
  #   end
  # end

end
