require "spec_helper"

describe RailsQL::Builder::TypeFactory do
  let :root_builder do
    RailsQL::Builder::TypeBuilder.new
  end

  let :root_type_klass do
    Class.new(RailsQL::Type)
  end

  let :args_type_klass do
    Class.new(RailsQL::Type)
  end

  let :child_type_klass do
    Class.new(RailsQL::Type)
  end

  let :grandchild_type_klass do
    Class.new(RailsQL::Type)
  end

  describe "#build!" do

    context "for fields" do

      let :child_builder do
        RailsQL::Builder::TypeBuilder.new(
          name: "child_stuff",
          aliased_as: "child_stuff_alias"
        )
      end

      let :grandchild_builder do
        RailsQL::Builder::TypeBuilder.new(
          name: "grandchild_stuff",
          aliased_as: "grandchild_stuff_alias"
        )
      end

      let :root_type do
        described_class.build!(
          variable_builders: [],
          type_klass: root_type_klass,
          builder: root_builder,
          ctx: {wat: "wat"}
        )
      end

      let :child_type do
        root_type.field_types["child_stuff_alias"]
      end

      let :grandchild_type do
        child_type.field_types["grandchild_stuff_alias"]
      end

      before :each do
        root_type_klass.field(:child_stuff,
          type: child_type_klass,
          child_ctx: {wat_level_2: 2}
        )
        root_builder.child_builders << child_builder

        child_type_klass.field(:grandchild_stuff,
          type: grandchild_type_klass,
          child_ctx: {wat_level_3: 3}
        )
        child_builder.child_builders << grandchild_builder
      end

      it "creates the nested types" do
        expect(child_type.class).to eq child_type_klass
        expect(child_type.aliased_as).to eq "child_stuff_alias"
        expect(child_type.field_or_arg_name).to eq "child_stuff"

        expect(grandchild_type.class).to eq grandchild_type_klass
        expect(grandchild_type.aliased_as).to eq "grandchild_stuff_alias"
        expect(grandchild_type.field_or_arg_name).to eq "grandchild_stuff"
      end

      it "sets the ctx" do
        expect(root_type.ctx).to eq(
          wat: "wat"
        )
        expect(child_type.ctx).to eq(
          wat: "wat",
          wat_level_2: 2
        )
        expect(grandchild_type.ctx).to eq(
          wat: "wat",
          wat_level_2: 2,
          wat_level_3: 3
        )
      end
    end

    context "for args and input objects" do

      let :child_builder do
        RailsQL::Builder::TypeBuilder.new(
          name: "child_stuff",
          aliased_as: "child_stuff"
        )
      end

      let :grandchild_builder do
        RailsQL::Builder::TypeBuilder.new(
          name: "grandchild_stuff",
          aliased_as: "grandchild_stuff"
        )
      end

      let :root_type do
        field_definition = instance_double(RailsQL::Field::FieldDefinition,
          args_type_klass: args_type_klass
        )
        described_class.build!(
          variable_builders: [],
          type_klass: root_type_klass,
          field_definition: field_definition,
          builder: root_builder,
          ctx: {wat: "wat"}
        )
      end

      let :child_type do
        root_type.args_type.field_types["child_stuff"]
      end

      let :grandchild_type do
        child_type.field_types["grandchild_stuff"]
      end

      before :each do
        args_type_klass.field(:child_stuff,
          type: child_type_klass,
          child_ctx: {wat_level_2: 2},
          args: ->(args) {
            args.field(:child_stuff,
              type: child_type_klass
            )
          }
        )
        child_type_klass.field(:grandchild_stuff,
          type: grandchild_type_klass,
          child_ctx: {wat_level_3: 3}
        )

        root_builder.arg_type_builder = RailsQL::Builder::TypeBuilder.new(
          is_input: true
        )
        root_builder.arg_type_builder.child_builders << child_builder
        child_builder.child_builders << grandchild_builder
      end

      it "creates the nested types" do

        expect(child_type.class).to eq child_type_klass
        expect(child_type.aliased_as).to eq "child_stuff"
        expect(child_type.field_or_arg_name).to eq "child_stuff"

        expect(grandchild_type.class).to eq grandchild_type_klass
        expect(grandchild_type.aliased_as).to eq "grandchild_stuff"
        expect(grandchild_type.field_or_arg_name).to eq "grandchild_stuff"
      end

      it "sets the ctx" do
        expect(root_type.ctx).to eq(
          wat: "wat"
        )
        expect(root_type.args_type.field_types["child_stuff"].ctx).to eq(
          wat: "wat",
          wat_level_2: 2
        )
      end
    end

    it "creates nested types based on variables" do
      pending "variable builders"
      fail
    end

    context "lists of object types" do
      let :child_builder do
        RailsQL::Builder::TypeBuilder.new(
          name: "child_stuff",
          aliased_as: "child_stuff"
        )
      end

      let :root_type do
        described_class.build!(
          variable_builders: [],
          type_klass: root_type_klass,
          builder: root_builder,
          ctx: {}
        )
      end

      let :list_type do
        root_type.field_types["child_stuff"]
      end

      let :child_type do
        list_type.query_tree_children.first
      end

      before :each do
        root_type_klass.field(:child_stuff,
          type: RailsQL::Type::List.of(child_type_klass)
        )
        root_builder.child_builders << child_builder
      end

      it "creates the list type" do
        expect(child_type.class).to eq child_type_klass
        expect(list_type.aliased_as).to eq "child_stuff"
        expect(list_type.field_or_arg_name).to eq "child_stuff"
      end
    end

    context "creates lists of input object types" do
      it "creates the nested types" do

      end
    end

    context "creates non-nullables and their wraped types" do
      it "creates the nested types" do

      end
    end

    it "creates chains of directives and their wrapped types" do
      pending "directives"
      fail
    end

    it "creates unions and their children (their unioned types)" do
      pending "unions"
      fail
    end

  end
end
