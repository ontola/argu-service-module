# frozen_string_literal: true

class Page < ActiveResourceModel
  include LinkedRails::Model

  def from
    "#{display_name.split(',').first} <noreply@argu.co>"
  end

  def iri
    RDF::URI("https://#{iri_prefix}")
  end

  def url
    iri_prefix.split('/').last.presence || iri_prefix
  end

  def tenant
    @tenant ||=
      OpenStruct.new(
        host: iri_prefix.split('/').first,
        path: iri_prefix.split('/')[1..].join('/')
      )
  end

  class << self
    def default
      new(iri_prefix: "#{ENV['HOSTNAME']}/argu", database_schema: 'argu', display_name: 'Argu')
    end
  end
end
