# frozen_string_literal: true

class CollectionSerializer < LinkedRails::CollectionSerializer
  attribute :action_dialog, predicate: NS.ontola[:actionDialog]
end
