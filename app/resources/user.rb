# frozen_string_literal: true

class User < ActiveResourceModel
  self.collection_name = 'u'

  def language
    return attributes['language'].split('language#').second if attributes['language']&.include?('language#')

    attributes['language'] || I18n.default_locale
  end
end
