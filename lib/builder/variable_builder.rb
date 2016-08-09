# Pending dev time

require_relative "./type_builder.rb"

module RailsQL
  module Builder
    class VariableBuilder < TypeBuilder
      attr_accessor :variable_name, :of_type
    end
  end
end

#
# module RailsQL
#   module Builder
#     class VariableBuilder
#       delegate(
#         *(TypeBuilder.instance_methods - Object.methods),
#         to: :type_builder
#       )
#
#       attr_accessor(
#         :variable_name,
#         :default_value,
#         :type_klass,
#         :default_value_builder
#       )
#       attr_reader :type_builder
#
#       def is_input?
#         true
#       end
#
#       # TODO: migrate to operate on a single variable builder
#       def parse!(variable_definitions:, variable_values:, type_names_whitelist:)
#         variable_builders = {}
#         variable_definitions.each do |variable_name, type_name|
#           # do not allow the user to input a type name without
#           # whitelisting it against a schema
#           unless type_names_whitelist.include? type_name
#             raise InvalidArgType, "type #{type_name} is not defined"
#           end
#           value = variable_values[variable_name]
#           root = Builder.new(
#             type_klass: type_name,
#             model: value
#           )
#           visitor = Visitor.new(query_root_builder: root)
#           vistor.visit_operation_definition build_node(value: "query")
#           variable_builders[variable_name] = parse_variable_tree!(
#             variable_value: value,
#             visitor: visitor
#           )
#         end
#         return variable_builders
#       end
#
#       private
#
#       def parse_variable_tree!(variable_value:, visitor:)
#         return unless variable_value.is_a? Hash
#         variable_value.each do |k, v|
#           visit(:name, visitor: visitor, value: k)
#           visit(:arg_value, visitor: visitor, value: v) do
#             parse_variable_tree! variable_value: v, visitor: visitor
#           end
#         end
#       end
#
#       def visit(sym, visitor:, value:)
#         node = build_node value: value
#         visitor.send :"visit_#{sym}", node
#         yield is passed_block?
#         visitor.send :"end_visit_#{sym}", node
#       end
#
#       def build_node(attrs)
#         OpenStruct.new attrs
#       end
#
#     end
#   end
# end
