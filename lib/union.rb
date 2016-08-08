require_relative "./type/type.rb"
require_relative "./field/field_definition.rb"

module RailsQL
  class Union < RailsQL::Type
    kind :union

    attr_reader :unioned_types

    def initialize(unioned_types:, **opts)
      @unioned_types = unioned_types
      super opts
    end

    def query_tree_children
      @unioned_types
    end

    # example useage:
    # def resolve_tree_children
    #   model.is_a? Desert ? union_types[:dessert] : union_types[:entre]
    # end
    def resolve_tree_children
      raise "Unions must overwrite #resolve_tree_children"
    end

    def as_json
      resolve_tree_children.first.as_json
    end

    def self.union_definitions
      @union_definitions ||= {}
    end

    # example useage:
    #
    # unions(:dessert,
    #   query: ->(args, child_query) {},
    #   resolve: ->(args, child_query) {},
    #   type_klass: "Dessert"
    # )
    #
    # unions(:entre,
    #   query: ->(args, child_query) {},
    #   resolve: ->(args, child_query) {},
    #   type_klass: "Dessert"
    # )
    def self.unions(*union_definition_opts)
      name = union_definition_opts[:name]
      union_definitions[name] = FieldDefinition.new union_definition_opts
    end

  end
end
