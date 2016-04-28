require "spec_helper"

describe RailsQL::DataType::IntrospectSchema do
  let(:introspect_schema) {Class.new described_class}

  let(:schema) do
    klass = Class.new RailsQL::DataType::Base
    klass.field :user_count, data_type: :Integer
    klass.field :user, data_type: :user_data_type
    klass
  end

  let(:user_data_type_klass) do
    UserDataType = Class.new RailsQL::DataType::Base
    UserDataType.description "User of the app"
    UserDataType.field :email, data_type: :String
    UserDataType
  end

  describe "recurse_over_data_type_klasses" do
    it "returns an array with the name and description of every data_type" do
      user_data_type_klass
      results = introspect_schema.new.recurse_over_data_type_klasses schema

      expect(results.include?(
        "name" => "UserDataType",
        "description" => "User of the app"
      )).to eq true
      expect(results.include?(
        "name" => "Integer",
        "description" => RailsQL::DataType::Primative::Integer.description
      )).to eq true
      expect(results.include?(
        "name" => "String",
        "description" => RailsQL::DataType::Primative::String.description
      )).to eq true
    end
  end
end