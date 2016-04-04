require 'rubygems'
require 'awesome_print'
require 'graphql/parser'

RSpec.configure do |config|
  Dir[File.expand_path('../lib/*', File.dirname(__FILE__))].each {|f| require f }

  config.before :all do
  end

  config.after :each do
  end

  config.warnings = false
  RSpec::Expectations.configuration.warn_about_potential_false_positives = false

  config.order = "random"
end
