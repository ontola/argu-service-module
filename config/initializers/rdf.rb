# frozen_string_literal: true

module RDF
  module Term
    def as_json(_opts = {})
      to_s
    end
  end

  class URI
    delegate :present?, to: :to_s
  end

  class DynamicURI < RDF::URI
    def rewrite_value!
      return if @rewriten
      @rewriten = true
      @value = value.sub("https://#{ENV['HOSTNAME']}", "https://app.#{ENV['HOSTNAME']}").freeze
      self
    end
  end

  def self.DynamicURI(uri, *args, &block)
    uri.respond_to?(:to_uri) ? uri.to_uri : DynamicURI.new(uri, *args, &block)
  end
end

module RDFStatementRewrite
  def initialize!
    @subject.rewrite_value! if @subject.is_a?(RDF::DynamicURI)
    @object.rewrite_value! if @object.is_a?(RDF::DynamicURI)
    super
  end
end

RDF::Statement.send(:prepend, RDFStatementRewrite)
