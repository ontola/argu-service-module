# frozen_string_literal: true

class Action
  include ActiveModel::Model, ActiveModel::Serialization, PragmaticContext::Contextualizable, Ldable
  attr_accessor :base_iri, :filter, :type, :resource_type
  contextualize_with_type(&:context_type)
  contextualize_with_id(&:id)
  contextualize :name, as: 'schema:name'
  contextualize :target, as: 'schema:target'

  def initialize(opts = {})
    opts[:type] = "#{opts.fetch(:type).to_s.camelize}Action"
    super
  end

  def context_type
    "schema:#{type}"
  end

  def id
    u = URI.parse(base_iri)
    u.fragment = type
    u.query = {filter: filter}.to_param if filter.present?
    u.to_s
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
