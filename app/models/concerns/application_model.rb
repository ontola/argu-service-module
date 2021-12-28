# frozen_string_literal: true

module ApplicationModel
  extend ActiveSupport::Concern

  included do
    include IRITemplateHelper
  end

  def class_name
    self.class.name.tableize
  end

  def collection_iri(collection, **opts)
    ActsAsTenant.with_tenant(opts.delete(:root) || ActsAsTenant.current_tenant) { super }
  end

  def edited?
    updated_at - 2.minutes > created_at
  end

  def identifier
    "#{class_name}_#{id}"
  end

  def added_delta
    []
  end

  def removed_delta
    added_delta
  end

  module ClassMethods
    def class_name
      name.tableize
    end

    def collection_iri(**opts)
      ActsAsTenant.with_tenant(opts.delete(:root) || ActsAsTenant.current_tenant) { super }
    end
  end
end
