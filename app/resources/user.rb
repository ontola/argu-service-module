# frozen_string_literal: true

class User < ActiveResourceModel
  def self.collection_name
    'u'
  end
end
