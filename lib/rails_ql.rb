require "active_support/all"
require 'graphql/parser'

# load concerns first so classes can reference them
Dir[File.expand_path('./**/concerns/*.rb', File.dirname(__FILE__))].each do |f|
  require f
end

Dir[File.expand_path('./errors/*.rb', File.dirname(__FILE__))].each do |f|
  require f
end

Dir[File.expand_path('./**/*.rb', File.dirname(__FILE__))].each do |f|
  require f
end


module RailsQL
end
