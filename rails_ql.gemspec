Gem::Specification.new do |s|
  s.name = "rails_ql"
  s.version = "0.1.0"
  s.summary = "GraphQL for Rails"
  s.authors = ["Rob Gilson", "Stuart Garvagh"]
  # s.add_runtime_dependency "graphql-parser" #,
    # [">= 0.0.2"]
  s.add_runtime_dependency "activesupport",
    [">= 4.0.0"]
  s.add_runtime_dependency "activemodel",
    [">= 4.0.0"]

  s.add_development_dependency "rspec",
    [">= 3.4.0"]
  s.add_development_dependency "awesome_print",
    [">= 1.6.1"]

  s.add_development_dependency "pry",
    [">= 0.10.4"]

end
