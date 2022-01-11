# frozen_string_literal: true

require 'oauth2'

module Argu
  class API # rubocop:disable Metrics/ClassLength
    include ServiceHelper
    include URITemplateHelper
    include JWTHelper

    def initialize(service_token: nil, user_token: nil)
      @service_token = service_token
      @user_token = user_token
    end
    attr_reader :service_token, :user_token

    def authorize_action(**opts)
      opts[:authorize_action] = opts.delete(:action)
      api_request(:argu, :get, uri_template(:spi_authorize).expand(opts))
    rescue OAuth2::Error
      false
    end

    def authorize_redirect_resource(token)
      authorize_action(resource_iri: token.redirect_url, action: :show) if token&.redirect_url
    end

    def confirm_email_address(email)
      api_request(
        :argu,
        :put,
        expand_uri_template(:user_confirmation),
        token: service_token,
        body: {email: email},
        headers: {accept: 'application/json'}
      )
    end

    def couple_email(email)
      api_request(
        :argu,
        :put,
        '/user',
        token: user_token,
        body: {user: {email_addresses_attributes: {999 => {email: email}}}},
        headers: {accept: 'application/json'}
      )
    end

    def create_email(template, recipient, **options) # rubocop:disable Metrics/MethodLength
      recipient_opts = recipient.slice(:email, :language, :id)
      display_name = recipient[:display_name] || recipient.try(:name_with_fallback)
      recipient_opts[:display_name] = display_name if display_name

      api_request(
        :email,
        :post,
        expand_uri_template(:email_spi_create),
        token: service_token,
        body: {email: {template: template, recipient: recipient_opts, options: options}},
        headers: {accept: 'application/json'}
      )
    end

    def create_membership(token)
      api_request(
        :argu,
        :post,
        expand_uri_template(:group_membership_create_iri, group_id: token.group_id),
        body: {token: token.secret},
        headers: {accept: 'application/json'}
      )
    end

    def create_user(email, headers: nil, redirect: nil)
      response = create_user_request(email, redirect)
      update_user_token(headers, response)
      user_from_response(response, email)
    rescue OAuth2::Error
      nil
    end

    def email_address_exists?(email)
      api_request(:argu, :get, expand_uri_template(:spi_email_addresses, email: email), token: service_token)
      true
    rescue OAuth2::Error
      false
    end

    def get_tenant(iri)
      result = raw_api_request(:argu, :get, expand_uri_template(:spi_find_tenant, iri: iri), token: service_token)
      body = JSON.parse(result.body)
      Page.new(body)
    rescue OAuth2::Error
      nil
    end

    def get_tenants # rubocop:disable Naming/AccessorMethodName
      result = raw_api_request(:argu, :get, '/_public/spi/tenants', token: service_token)
      JSON.parse(result.body)['schemas']
    end

    def self.service_api
      new(service_token: ENV['SERVICE_TOKEN'])
    end

    def user_is_group_member?(group_id)
      authorize_action(
        resource_type: 'Group',
        resource_id: group_id,
        action: 'is_member'
      )
    end

    def verify_token(token, group_id)
      api_request(
        :token,
        :get,
        expand_uri_template(:verify_token, jwt: sign_payload(secret: token, group_id: group_id)),
        token: service_token
      )
      true
    rescue OAuth2::Error => e
      Bugsnag.notify(e)

      false
    end

    private

    def api_request(service, method, path, **opts)
      opts[:headers] = default_headers.merge(opts[:headers] || {})
      raw_api_request(service, method, path_with_prefix(path), **opts)
    end

    def create_user_request(email, redirect)
      api_request(
        :argu,
        :post,
        expand_uri_template(:user_registration),
        body: {user: {email: email}, redirect_url: redirect},
        headers: {accept: 'application/json'}
      )
    end

    def default_headers
      {
        'X-Forwarded-Host': ActsAsTenant.current_tenant.tenant.host,
        'X-Forwarded-Proto': 'https'
      }
    end

    def path_with_prefix(path)
      uri = URI("https://#{ActsAsTenant.current_tenant.iri_prefix}#{path}")
      [uri.path, uri.query.presence].compact.join('?')
    end

    def raw_api_request(service, method, path, **opts)
      token = opts.delete(:token)
      service(service, token: token || user_token)
        .request(method, path, opts)
    end

    def user_from_response(response, email)
      attributes = JSON.parse(response.body)
      attributes['included'] = [
        {attributes: {email: email, primary: true}}
          .merge(attributes.dig('data', 'relationships', 'email_addresses', 'data').first)
      ]
      CurrentUser.from_response(user_token, User.new(attributes))
    end

    def update_user_token(headers, response)
      @user_token = response.headers['new-authorization']
      Bugsnag.notify('No new user token received') if @user_token.blank?

      headers['new-authorization'] = response.headers['new-authorization']
      headers['new-refresh-token'] = response.headers['new-refresh-token']
    end
  end
end
