# frozen_string_literal: true

class Page < ActiveResourceModel
  include LinkedRails::Model

  def url
    iri_prefix.split('/').last.presence || iri_prefix
  end

  def use_new_frontend
    false
  end

  class << self
    def default
      new(iri_prefix: "app.#{ENV['HOSTNAME']}/argu", database_schema: 'argu')
    end
  end
end
