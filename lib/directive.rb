# Directives wrap fields and allow custom behaviour to be injected by
# overwritting the methods which are by default delegated to the field.
#
# TODO: Integrate Directives with the builders and visitor
# TODO: Refactor directives as types.
# TODO: Figure out how these interact with fragments, fields and operations
module RailsQL
  class Directive < RailsQL::Type

    attr_reader :modified_type

    def initialize(modified_type:, **opts)
      @modified_type = modified_type
      super **opts
    end

    def self.locations(locations)
      valid_locations = [
        :QUERY,
        :MUTATION,
        :FIELD,
        :FRAGMENT_DEFINITION,
        :FRAGMENT_SPREAD,
        :INLINE_FRAGMENT
      ]
      invalid_locations = locations - valid_locations
      if invalid_locations.present?
        raise <<-ERROR
          locations #{invalid_locations.join(",")} are not one of
          #{valid_locations.join(",")}
        ERROR
      end
      @locations = locations
    end

    def self.anonymous_input_object
      @anonymous_input_object ||= Class.new RailsQL::Type::AnonymousInputObject
    end

    def self.args(args_lambda)
      args_lambda.call anonymous_input_object
    end

    [
      :appended_parent_query,
      :resolve_child_types!,
      :inject_into_parent_json
    ].each do |k|
      delegate k, to: :modified_type
    end

  end
end
