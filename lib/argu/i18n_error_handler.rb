# frozen_string_literal: true

class I18nErrorHandler
  def call(exception, _locale, _key, _options)
    raise exception.to_exception
  end
end
