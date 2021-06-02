# frozen_string_literal: true

module ApplicationModel
  extend ActiveSupport::Concern

  included do
    include IRITemplateHelper
  end

  def canonical_iri
    super if persisted?
  end

  def canonical_iri_opts
    return iri_opts unless respond_to?(:id)

    {id: id, "#{self.class.name.underscore}_id": id}
  end

  def class_name
    self.class.name.tableize
  end

  def edited?
    updated_at - 2.minutes > created_at
  end

  def identifier
    "#{class_name}_#{id}"
  end

  def iri_opts
    {id: to_param, "#{self.class.name.underscore}_id": to_param}
  end

  def added_delta
    []
  end

  def removed_delta
    []
  end

  module ClassMethods
    def class_name
      name.tableize
    end
  end
end
