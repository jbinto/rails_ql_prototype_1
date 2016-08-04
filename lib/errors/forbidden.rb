module RailsQL
  class Forbidden < Exception
    attr_reader :errors_json

    def initialize(msg, errors_json:)
      @errors_json = errors_json
      super msg
    end
  end
end
