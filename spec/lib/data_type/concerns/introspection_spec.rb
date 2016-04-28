require "spec_helper"

describe RailsQL::DataType::Introspection do
  let(:data_type_klass) {
    klass = Class.new RailsQL::DataType::Base
    klass.field :example_field, data_type: class_double(RailsQL::DataType::Base)
    klass.has_one :child_data_type, data_type: klass
    klass
  }

  describe "included do" do
  end

end


