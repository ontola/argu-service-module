# frozen_string_literal: true

require 'oauth2'

module Argu
  class API # rubocop:disable Metrics/ClassLength
    include URITemplateHelper
    include JWTHelper

    attr_reader :user_token

    def initialize(user_token: nil)
      @user_token = user_token
    end

    def authorize_action(**opts)
      opts[:authorize_action] = opts.delete(:action)
      api_request(
        user_client(:data),
        :get,
        uri_template(:spi_authorize).expand(opts)
      )
    end

    def authorize_redirect_resource(token)
      authorize_action(resource_iri: token.redirect_url, action: :show) if token&.redirect_url
    rescue OAuth2::Error
      false
    end

    def confirm_email_address(email)
      api_request(
        service_client(:data),
        :put,
        expand_uri_template(:user_confirmation),
        body: {email: email},
        headers: {accept: 'application/json'}
      )
    end

    def couple_email(email)
      api_request(
        user_client(:data),
        :put,
        '/user',
        body: {user: {email_addresses_attributes: {999 => {email: email}}}},
        headers: {accept: 'application/json'}
      )
    end

    def create_email(template, recipient, **options)
      api_request(
        service_client(:email),
        :post,
        expand_uri_template(:email_spi_create),
        body: {email: create_email_body(template, recipient, options)},
        headers: {accept: 'application/json'}
      )
    end

    def create_membership(token)
      api_request(
        user_client(:data),
        :post,
        expand_uri_template(:group_memberships_iri, group_id: token.group_id),
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
      api_request(
        service_client(:data),
        :get,
        expand_uri_template(:spi_email_addresses, email: email)
      )
      true
    rescue OAuth2::Error
      false
    end

    def get_tenant(iri)
      result = api_request(
        service_client(:data),
        :get,
        expand_uri_template(:spi_find_tenant, iri: iri)
      )
      body = JSON.parse(result.body)
      Page.new(body)
    rescue OAuth2::Error
      nil
    end

    def user_is_group_member?(group_id)
      authorize_action(
        resource_type: 'Group',
        resource_id: group_id,
        action: 'is_member'
      )
    rescue OAuth2::Error
      false
    end

    def verify_token(token, group_id)
      api_request(
        service_client(:token),
        :get,
        expand_uri_template(:verify_token, jwt: sign_payload(secret: token, group_id: group_id))
      )
      true
    rescue OAuth2::Error => e
      Bugsnag.notify(e)

      false
    end

    private

    def api_request(client, method, path, **opts)
      opts[:headers] = default_headers.merge(opts[:headers] || {})
      client.request(method, path_with_prefix(path), **opts)
    end

    def create_email_body(template, recipient, options)
      body = {
        template: template,
        recipient: create_email_recipient_opts(recipient)
      }
      body[:mail_identifier] = options.delete(:mail_identifier) if options.key?(:mail_identifier)
      body[:options] = options
      body
    end

    def create_email_recipient_opts(recipient)
      recipient_opts = recipient.slice(:email, :language, :id)
      display_name = recipient[:display_name] || recipient.try(:name_with_fallback)
      recipient_opts[:display_name] = display_name if display_name
      recipient_opts[:language] ||= I18n.locale
      recipient_opts
    end

    def create_user_request(email, redirect)
      api_request(
        service_client(:data),
        :post,
        expand_uri_template(:user_registration),
        body: {user: {email: email}, redirect_url: redirect},
        headers: {accept: 'application/json'}
      )
    end

    def default_headers
      {
        'X-Forwarded-Host': ActsAsTenant.current_tenant&.tenant&.host,
        'X-Forwarded-Proto': 'https'
      }
    end

    def path_with_prefix(path)
      return path if ActsAsTenant.current_tenant.nil?

      uri = URI("https://#{ActsAsTenant.current_tenant.iri_prefix}#{path}")
      [uri.path, uri.query.presence].compact.join('?')
    end

    def service_client(service)
      Argu::Service.new(service).client(Argu::OAuth.service_token)
    end

    def user_client(service)
      Argu::Service.new(service).client(user_token)
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
