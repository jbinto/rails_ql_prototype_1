require "active_support/all"
require 'graphql/parser'

# load concerns first so classes can reference them
[
  './**/concerns/*.rb',
  './errors/*.rb',
  './field/*.rb',
  './type/*.rb',
  './**/*.rb'
].each do |glob|
  Dir[File.expand_path(glob, File.dirname(__FILE__))].each do |f|
    require f
  end
end

module RailsQL
end
