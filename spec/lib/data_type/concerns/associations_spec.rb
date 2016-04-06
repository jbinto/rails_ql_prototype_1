require "spec_helper"

describe RailsQL::DataType::Associations do
  shared_examples 'data_type_association' do |method_name|
    it "adds a field definition for the association" do
      pending
      fail
    end
  end

  describe ".has_many" do
    it_behaves_like "data_type_association", :has_many
  end

  describe ".has_one" do
    it_behaves_like "data_type_association", :has_one
  end

end