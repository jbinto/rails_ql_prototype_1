require 'graphql/parser'
puts GraphQL::Visitor

class RailsQLVisitor < GraphQL::Visitor

  attr_accessor :node_stack
  attr_reader :data_type_stack
  attr_reader :schema

  def initialize(top_level_data_type)
    @top_level_data_type = top_level_data_type
    @fragments = {}
    @data_type_stack = [@top_level_data_type]
    @node_stack = []
  end

  def current_data_type
    data_type_stack.last
  end

  def end_visit_field(node)
    node_stack.pop
    data_type_stack.pop
    end_visit_node :field, node
  end

  def visit_name(node)
    case node_stack.last
    when :field then visit_field_name node
    when :fragment_spread then visit_fragment_spread_name node
    when :fragment_definition then visit_fragment_definition_name node
    end
    visit_node :name, node
  end

  def visit_field_name(node)
    name = node.value
    field_definition = current_data_type.field_definitions[name]
    raise "Invalid field #{name}" if field_definition == nil
    next_klass = field_definition[:klass]
    next_data_type = current_data_type.children[name.to_sym]
    next_data_type ||= next_klass.new(parent: current_data_type)
    current_data_type.children[name.to_sym] = next_data_type
    @data_type_stack.push(next_data_type)
  end

  def visit_fragment_spread_name(node)
    fragment = (@fragments[node.value] ||= {referenced_by: []})
    fragment[:referenced_by] << current_data_type
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
    if name.match /^visit_/
      visit_node name.gsub("visit_", "").to_sym, node
    elsif name.match /^end_visit_/
      end_visit_node name.gsub("end_visit_", "").to_sym, node
    else
      super *args
    end
  end

  def visit_node(sym, node)
    puts sym
    node_stack.push(sym)
    (@current_visitors||[]).each do |visitor|
      visitor.send(:"visit_#{sym}", node)
    end
  end

  def end_visit_node(sym, node)
    node_stack.pop
    (@current_visitors||[]).each do |visitor|
      visitor.send(:"end_visit_#{sym}", node)}
  end

end
