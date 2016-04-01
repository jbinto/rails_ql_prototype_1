require 'rubygems'
require 'graphql/parser'
require 'rspec/rails'

RSpec.configure do |config|
    config.before :all do
    end

    config.after :each do
    end

    config.warnings = false
    RSpec::Expectations.configuration.warn_about_potential_false_positives = false

    config.order = "random"
  end
end
