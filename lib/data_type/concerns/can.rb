require 'active_support/concern'

#
module RailsQL
  module DataType
    module Can
      extend ActiveSupport::Concern

      included do
        after_resolve :authenticate_query!
      end

      module ClassMethods
      end

    end
  end
end
