require 'rubygems'
require 'awesome_print'
require 'simplecov'
require "./lib/rails_ql"
require 'pry'

RSpec.configure do |config|

  config.before :all do
  end

  config.after :each do
  end

  config.warnings = false
  RSpec::Expectations.configuration.warn_about_potential_false_positives = false

  config.order = "random"

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true


end
