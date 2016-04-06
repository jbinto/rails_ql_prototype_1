require 'active_support/concern'

# Stores associations in field_definitions. Each field definition is in the
# form:
#
# {
#   data_type: MyDataType || :my_data_type,
#   args: [:id],
#   resolve: (args, child_query) ->{ model.send(:my_association_name) }
#   query: (args, child_query) ->{ return query.where(id: args[:id]) }
#   description: "my association description"
# }
module RailsQL
  module DataType
    module Associations
      extend ActiveSupport::Concern

      class_methods do
        def has_many(name, opts)
          # add to field definitions
          defaults = {
            data_type: opts[:data_type] || name,
            args: [],
            resolve: ->(args, child_query) { model.send(data_type.to_s) },
            query: nil
          }
          (field_definitions[name] ||= defaults).merge! opts

          # TODO: Move this to where you make use of the definition
          # if [Symbol, String].includes? opts[:data_type].class
          #   opts[:data_type] = opts[:data_type].to_s.classify.constantize
          # end
        end

        alias_method :has_one, :has_many

      end

    end
  end
end


# RailsQL::Runner.execute(graphql)


# 1. visitor -> data type heirarchy (runs after_initialize)
#   static analysis on data type heirarchy
# 2. runs "parse" hooks (eg: traverse)
# 3. returns results
