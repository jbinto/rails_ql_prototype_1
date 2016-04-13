require 'graphql/parser'
puts GraphQL::Visitor

module RailsQL
  class Visitor < GraphQL::Visitor

    attr_accessor :node_stack
    attr_reader :data_type_builder_stack
    attr_reader :root

    def initialize(root_builder)
      @root = root_builder
      @fragments = {}
      @data_type_builder_stack = [root]
      @node_stack = []
    end

    protected

    def current_data_type_builder
      data_type_builder_stack.last
    end

    def end_visit_field(node)
      node_stack.pop
      data_type_builder_stack.pop
      end_visit_node :field, node
    end

    def visit_name(node)
      @current_name = node.value
      case node_stack.last
      when :field then visit_field_name node
      when :fragment_spread then visit_fragment_spread_name node
      when :fragment_definition then visit_fragment_definition_name node
      end
      visit_node :name, node
    end

    def visit_field_name(node)
      name = node.value
      next_data_type_builder = current_data_type_builder.add_child_builder name
      @data_type_builder_stack.push next_data_type_builder
    end

    def visit_int_value(node)
      visit_arg_value node.value.to_i
    end

    def visit_arg_value(value)
      current_data_type_builder.add_arg @current_name, value
    end

    def visit_fragment_spread_name(node)
      fragment = (@fragments[node.value] ||= {referenced_by: []})
      fragment[:referenced_by] << current_data_type_builder
    end

    def visit_fragment_definition_name(node)
      @current_fragment = @fragments[node.value]
      @current_visitors = @current_fragment[:referenced_by].map do |data_type|
        RailsQLVisitor.new(data_type)
      end
    end

    def end_visit_fragment_definition(node)
      @current_fragment = nil
      @current_visitors = nil
      end_visit_node :fragment_definition, node
    end

    def method_missing(*args)
      super *args if args.length != 2
      sym, node = args
      name = sym.to_s
      # puts name
      if name.match /^visit_/
        visit_node name.gsub("visit_", "").to_sym, node
      elsif name.match /^end_visit_/
        end_visit_node name.gsub("end_visit_", "").to_sym, node
      else
        super *args
      end
    end

    def visit_node(sym, node)
      # puts sym
      node_stack.push(sym)
      (@current_visitors||[]).each do |visitor|
        visitor.send(:"visit_#{sym}", node)
      end
    end

    def end_visit_node(sym, node)
      node_stack.pop
      (@current_visitors||[]).each do |visitor|
        visitor.send(:"end_visit_#{sym}", node)
      end
    end
  end
end
