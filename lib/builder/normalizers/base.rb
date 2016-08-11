module RailsQL
  module Builder
    module Normalizers
      class Base
        attr_reader :variable_definitions

        def initialize(
          variable_definitions:
          type_klass:,
          builder:
        )
          @variable_definitions = variable_definitions
          @root_node = {
            field_definition: nil,
            type_klass: type_klass,
            builder: builder
          }
        end

        def normalize!
          BuilderTreeVisitor.new.visit @root_node, {|node| visit_builder! node}
        end

      end
    end
  end
end
