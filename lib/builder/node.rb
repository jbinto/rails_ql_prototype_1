require_relative "./annotation.rb"

module RailsQL
  module Builder
    class Node

      delegate(
        *Annotation.instance_methods(false),
        to: :annotation
      )

      delegate(
        :ctx,
        :child_types=,
        :list_of_resolved_types=,
        to: :type
      )

      delegate(
        :modifier_type?,
        :union?,
        :of_type,
        to: :type_klass
      )

      NODE_ATTRS = [
        :child_nodes,
        :annotation,
        :field_definition,
        :type,
        :type_klass
      ]

      attr_accessor *(NODE_ATTRS - [:type_klass])

      attr_writer(
        :type_klass
      )

      def initialize(
          annotation: nil,
          child_nodes: [],
          type_klass: nil,
          type: nil,
          field_definition: nil,
          **annotation_attrs
        )
        @annotation = annotation
        @child_nodes = child_nodes
        @type_klass = type_klass
        @type = type
        @field_definition = field_definition
        if annotation_attrs.present?
          @annotation ||= Annotation.new
          annotation_attrs.each {|k, v| @annotation.send(:"#{k}=", v)}
        end
      end

      def type_klass
        @type_klass || field_definition.try(:type_klass)
      end

      def child_field_definitions
        type_klass.field_definitions
      end

      def shallow_clone_node
        clone_attrs = {}
        NODE_ATTRS.each {|k| clone_attrs[k] = self.send k}
        clone_attrs[:child_nodes] = [].concat child_nodes
        clone = Node.new clone_attrs
      end

      def duplicate_tree
        duplicate_node = BuilderNode.new
        duplicate_node.annotation = annotation
        # recursion
        duplicate_node.child_nodes = child_nodes.map(&:duplicate_tree).flatten
        return duplicate_node
      end

      def find_leaf_nodes
        if child_nodes.present?
          # recursion
          child_nodes.map(&:find_leaf_nodes).flatten
        else
          [self]
        end
      end

      def find_field_nodes_for_type(include_self: false)
        if field_or_input_field? && include_self
          [self]
        else
          child_nodes.map do |child_node|
            child_node.find_field_nodes_for_type include_self: true
          end.flatten
        end
      end

    end
  end
end
