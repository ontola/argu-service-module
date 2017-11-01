# frozen_string_literal: true

class Action
  include Ldable
  include Iriable
  include ActiveModel::Serialization
  include ActiveModel::Model
  attr_accessor :base_iri, :filter, :type, :resource_type

  def initialize(opts = {})
    opts[:type] = "#{opts.fetch(:type).to_s.camelize}Action"
    super
  end

  def id
    u = URI.parse(base_iri)
    u.fragment = type
    u.query = {filter: filter}.to_param if filter.present?
    u.to_s
  end

  def iri_opts
    {
      parent_iri: base_iri,
      type: type,
      only_path: true
    }
  end

  def name
    plural = resource_type.to_s.tableize
    I18n.t("#{plural}.collection.new.#{filter&.values&.join('.').presence || resource_type}",
           default: I18n.t('new_type', type: I18n.t("#{plural}.type")))
  end

  def target
    u = URI.parse(base_iri)
    u.path += '/new'
    u.query = {filter: filter}.to_param if filter.present?
    u.to_s
  end
end
