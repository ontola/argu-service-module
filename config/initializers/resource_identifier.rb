# frozen_string_literal: true
module ActiveModelSerializers
  module Adapter
    class JsonApi
      class ResourceIdentifier
        def type_for(serializer, transform_options)
          return serializer._type.call(serializer.object) if serializer._type.respond_to?(:call)
          self.class.type_for(serializer.object.class.name, serializer._type, transform_options)
        end
      end
    end
  end
end
