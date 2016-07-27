# Directives wrap fields and allow custom behaviour to be injected by
# overwritting the methods which are by default delegated to the field.
#
# TODO: Integrate Directives with the builders and visitor
module RailsQL
  class Directive

    attr_reader :field

    def initialize(field:)
      @field = field
    end

    [
      :appended_parent_query
      :resolve_child_types!
      :inject_into_parent_json
    ].each do
      delegate k, to: :field
    end

  end
end
