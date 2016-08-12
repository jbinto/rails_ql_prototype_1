module RailsQL
  module Builder
    class Node < Array

      delegate(
        *(Annotation.instance_methods - Object.methods),
        to: :annotation
      )

      delegate(
        :ctx,
        :child_types=,
        :modifier_type?,
        :union?,
        :directive?,
        :list_of_resolved_types=,
        to: :type
      )

      attr_accessor(
        :child_nodes
        :annotation,
        :ctx,
        :field_definition,
        :type
      )

      attr_writer(
        :type_klass
      )

      def initialize(child_nodes:, annotation:, **annotation_attrs)
        @child_nodes = child_nodes || []
        @annotation = annotation
        if annotation_opts.present?
          @annotation ||= Annotation.new
          annotation_attrs.each {|k, v| @annotation.send(:"#{k}=", v)}
        end
      end

      def type_klass
        @type_klass || field_definition.try :type_klass
      end

      def shallow_clone_node
        clone = BuilderNode.new(
          annotation: annotation,
          child_nodes: Array.new(child_nodes),
          ctx: ctx,
          type_klass: type_klass,
          type: type
        )
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

      def find_field_nodes
        field_nodes = child_nodes.map(&:find_feild_nodes).flatten
        field_nodes << self if field_definition.present?
        field_nodes
      end

    end
  end
end
