require "spec_helper"

describe RailsQL::DataType::Associations do
  describe ".can" do
    it "adds permissions to the field definitions" do
      pending
      fail
    end
  end

  describe "included" do
    it "adds after_resolve :authorize_query, if: :root? callback" do
    end
  end

  describe "#unauthorized_query_fields" do
    it "returns a subset of fields which cannot be read, including children" do
    end
  end

  describe "#authorize_query!" do
    context "when unauthorized_query_fields is not empty" do
    end

    context "when unauthorized_query_fields is empty" do
    end
  end

  describe "#authorize_mutation!" do
    pending "mutations"
    fail
  end

end


