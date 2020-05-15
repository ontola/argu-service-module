# frozen_string_literal: true

require 'oauth2'

module Argu
  class API # rubocop:disable Metrics/ClassLength
    include ServiceHelper
    include UriTemplateHelper
    include JWTHelper

    def initialize(service_token: nil, user_token: nil)
      @service_token = service_token
      @user_token = user_token
    end
    attr_reader :service_token, :user_token

    def authorize_action(opts = {})
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
        expand_uri_template(:user_confirm),
        token: service_token,
        body: {email: email},
        headers: {accept: 'application/json'}
      )
    end

    def couple_email(email)
      api_request(
        :argu,
        :put,
        expand_uri_template(:settings_iri, parent_iri: 'u'),
        token: user_token,
        body: {user: {email_addresses_attributes: {999 => {email: email}}}},
        headers: {accept: 'application/json'}
      )
    end

    def create_email(template, recipient, options = {})
      recipient = recipient.slice(:display_name, :email, :language, :id)
      api_request(
        :email,
        :post,
        expand_uri_template(:email_spi_create),
        token: service_token,
        body: {email: {template: template, recipient: recipient, options: options}},
        headers: {accept: 'application/json'}
      )
    end

    def create_membership(token)
      group_iri = expand_uri_template(:groups_iri, id: token.group_id)
      api_request(
        :argu,
        :post,
        collection_iri_path(group_iri, :group_memberships),
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

    def generate_guest_token(redirect: nil)
      result = api_request(
        :argu,
        :post,
        expand_uri_template(:oauth_token),
        token: user_token || service_token,
        body: guest_token_params(redirect)
      )
      parsed_body = JSON.parse(result.body)
      @user_token = parsed_body['access_token']

      parsed_body
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

    def api_request(service, method, path, opts = {})
      opts[:headers] = default_headers.merge(opts[:headers] || {})
      raw_api_request(service, method, path_with_prefix(path), opts)
    end

    def create_user_request(email, redirect)
      api_request(
        :argu,
        :post,
        expand_uri_template(:user_registration),
        body: {user: {email: email}, r: redirect},
        headers: {accept: 'application/json'}
      )
    end

    def default_headers
      {
        'X-Forwarded-Host': ActsAsTenant.current_tenant.tenant.host,
        'X-Forwarded-Proto': 'https'
      }
    end

    def guest_token_params(redirect)
      {
        client_id: ENV['ARGU_APP_ID'],
        client_secret: ENV['ARGU_APP_SECRET'],
        grant_type: :password,
        scope: :guest,
        r: redirect
      }
    end

    def path_with_prefix(path)
      uri = URI("https://#{ActsAsTenant.current_tenant.iri_prefix}#{path}")
      [uri.path, uri.query.presence].compact.join('?')
    end

    def raw_api_request(service, method, path, opts = {})
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
