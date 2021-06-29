# frozen_string_literal: true

module ApplicationModel
  extend ActiveSupport::Concern

  included do
    include IRITemplateHelper
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
