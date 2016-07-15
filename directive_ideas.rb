# https://facebook.github.io/graphql/#sec-Type-System.Directives
# and
# https://medium.com/apollo-stack/new-features-in-graphql-batch-defer-stream-live-and-subscribe-7585d0c28b07#.3ay3q7he0

class Post < RailsQL::Type
  initialQuery ->{Post.all}

  field(:comments,
    query: ->(parent_type, args, child_query, stream, defer, live, async) {
      if defer || stream
        query
      else
        query.eager_load(comments: ->(ds) {ds.tb_merge(child_query)})
      end
    },
    resolve: ->(parent_type, args, child_query, stream, defer, live, &triggerLiveUpdate, &block) {
      # if using resolve normally each call to block adds the comment to an array
      # if using resolve with defer each call to block sends a defered payload
      # to the client
      if live
        channel = ctx[:action_cable_channel]
        channel.subscribeTo(model, "moreCommentsAndStuff") do |comments|
          &triggerLiveUpdate comments
        end
      end
      if stream
        model.comments.find_each &block
      else
        model.comments.each &block
      end
    },
    directives: [LiveDirective]
  )
end


StoryType class {
  FieldDefinitionCollection {
    id: ID
    actor: String
    message: String
  }
}


StoryType instance (model = A) {
  FieldCollection {
    id: ExportDirective {
      StoryType instance (model = A) {
        id: ID
      }
    }
    actor: String
    message: String
  }
}

class Directive
  def field_name
    # TODO
  end

  def self.args
    # TODO
  end

  def child_type
    # TODO
  end

  def query(parent_type, args, child_query)
    child_query
  end

  def resolve_child_types!
    child_type.resolve_child_types!
  end

  def inject_into_parent_json(parent_json)
    parent_json.merge child_json
  end
end

module RailsQL
  class AsyncProvider
    attr_accessor :provider

    def self.perform(&block)
      provider.perform(&block)
      return RailsQL::DeferedObject.new
    end

    def perform(&block)
      raise "perform must be overwritten by subclass"
    end

    def broadcast(json)
      raise "broadcast must be overwritten by subclass"
    end
  end
end

module RailsQL
  class DeferedObject
    def as_json
      {}
    end
  end
end

class SkipDirective < RailsQL::Directive
  args -> (args) {
    args.field :if, type: "Boolean"
  }

  def skip?
    args[:if]
  end

  def query(parent_type, args, child_query)
    skip? ? nil : super
  end

  def resolve_child_types!
    skip? ? RailsQL::DeferedObject.new : super
  end

  def inject_into_parent_json(parent_json)
    skip? ? parent_json : super
  end
end

class IncludeDirective < SkipDirective
  def skip?
    !args[:if]
  end
end


class ExportDirective < RailsQL::Directive
  args -> (args) {
    args.field :as, type: "String"
  }

  def inject_into_parent_json(parent_json)
    child_json = child_type.as_json
    # Assuming next_operation_variables is implemented as a key value store
    # that gets used as variables for the subsequent operations in a graphQL
    # batched operation.
    (next_operation_variables[args[:as]] ||= []) << child_json[field_name]

    parent_json.merge child_json
  end
end

class DeferDirective < RailsQL::Directive
  # Do not resolve child types synchronously
  def resolve_child_types!
    RailsQL::AsyncProvider.perform do |provider|
      child_type.resolve_child_types!
      provider.broadcast(
        # TODO: automatically inject path into ctx in Types
        path: ctx[:path]
        data: child_type.as_json
      )
    end
  end
end

class StreamDirective < RailsQL::Directive
  # Do not resolve child types synchronously
  def resolve_child_types!
    index = 0
    RailsQL::AsyncProvider.perform do |provider|
      child_type.fields[field_name].stream do |type_at_index|
        provider.broadcast(
          # TODO: automatically inject path into ctx in Types
          path: "#{ctx[:path][index]}"
          data: type_at_index.as_json
        )
        index += 1
      end
    end
  end
end

class LiveDirective < RailsQL::Directive
  # Do not resolve child types synchronously
  def resolve_child_types!
    RailsQL::AsyncProvider.perform do |provider|
      child_type.fields[field_name].live do |type|
        types.each do |type|
          provider.broadcast(
            # TODO: automatically inject path into ctx in Types
            path: "#{ctx[:path]}"
            data: type.as_json
          )
        end
      end
    end
  end
end

# data type -> fields -> (directive -> field)* -> data type(s)

# data type -> fields -> data type(s)
# data type -> fields -> directive -> anonomous type -> anonomous field -> data type(s)
# data type -> fields -> directive  -> anonomous type -> anonomous field -> directive -> anonomous type -> anonomous field -> data type(s)

class NoOpDirective < RailsQL::Directive

end
