# frozen_string_literal: true

module ApplicationModel
  extend ActiveSupport::Concern

  included do |base|
    base.include Enhanceable

    def class_name
      self.class.name.tableize
    end

    def self.class_name
      name.tableize
    end

    def edited?
      updated_at - 2.minutes > created_at
    end

    def identifier
      "#{class_name}_#{id}"
    end
  end
end
