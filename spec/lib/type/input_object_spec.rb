require "spec_helper"

describe RailsQL::Type::InputObject do
  let(:input_obj_klass) {Class.new described_class}

  describe "#validate_input_args!" do
    before :each do
      input_obj_klass.input_field(:id,
        type: "Int", description: "The identifier value"
      )
    end

    context "when args have keys belonging to the defined args" do
      it "does not raise an error" do
        expect{input_obj_klass.validate_input_args!(id: 3)}.to_not raise_error
      end
    end

    context "when args have keys not belonging to the defined args" do
      it "raises an error" do
        expect{input_obj_klass.validate_input_args!(bogus_key: 3)}.to raise_error
      end
    end

    context "with required args" do
      before :each do
        input_obj_klass.input_field(:required_arg,
          type: "String", description: "Required!!", optional: false
        )
      end

      context "when all required args are present" do
        it "does not raise an error" do
          expect{input_obj_klass.validate_input_args!(
            required_arg: "Requirement satisfied!"
          )}.to_not raise_error
        end
      end

      context "when all required args are not present" do
        it "raises an error" do
          expect{input_obj_klass.validate_input_args!(id: 3)}.to raise_error
        end
      end
    end

    context "with nested input_object args" do
      before :each do
        NestedInputObj = Class.new described_class
        NestedInputObj.input_field :x, type: "Int", optional: true
        NestedInputObj.input_field :y, type: "Int", optional: false
        input_obj_klass.input_field(:nested,
          type: "NestedInputObj", description: "Required!!", optional: true
        )
      end

      context "when nested args have keys belonging to the defined nested args" do
        it "does not raise an error" do
          expect{input_obj_klass.validate_input_args!(
            nested: {x: 1, y: 2}
          )}.to_not raise_error
        end
      end

      context "when nested args have keys not belonging to the defined nested args" do
        it "does raises an error" do
          expect{input_obj_klass.validate_input_args!(
            nested: {x: 1, y: 2, z: 3}
          )}.to raise_error
        end
      end

      context "when nested args does not have required keys" do
        it "does raises an error" do
          expect{input_obj_klass.validate_input_args!(
            nested: {x: 1}
          )}.to raise_error
          expect{input_obj_klass.validate_input_args!(nested: {})}.to raise_error

          # the top level object is not required
          # only check required on nested keys if the top level object is present
          expect{input_obj_klass.validate_input_args!(id: 3)}.to_not raise_error
        end
      end
    end
  end
end
