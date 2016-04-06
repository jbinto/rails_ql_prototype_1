require "active_support/all"
require 'graphql/parser'

Dir[File.expand_path('./**/*.rb', File.dirname(__FILE__))].each do |f|
  require f
end


module RailsQL
end