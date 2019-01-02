# frozen_string_literal: true

require 'oauth2'

module Argu
  class API # rubocop:disable Metrics/ClassLength
    include ServiceHelper
    include UriTemplateHelper
    attr_reader :cookie_jar

    def initialize(service_token: nil, user_token: nil, cookie_jar: nil)
      @service_token = service_token
      @user_token = user_token
      @cookie_jar = cookie_jar
    end
    attr_reader :service_token, :user_token

    def authorize_action(opts = {})
      opts[:authorize_action] = opts.delete(:action)
      service(:argu).get(uri_template(:spi_authorize).expand(opts))
    rescue OAuth2::Error
      false
    end

    def authorize_redirect_resource(token)
      authorize_action(resource_iri: token.redirect_url, action: :show) if token&.redirect_url
    end

    def confirm_email_address(email)
      service(:argu, token: service_token)
        .put(expand_uri_template(:user_confirm), body: {email: email}, headers: {accept: 'application/json'})
    end

    def create_email(template, recipient, options = {})
      recipient = recipient.slice(:display_name, :email, :language, :id)
      service(:email, token: service_token).post(
        expand_uri_template(:email_spi_create),
        body: {email: {template: template, recipient: recipient, options: options}},
        headers: {accept: 'application/json'}
      )
    end

    def create_favorite(root_id, iri)
      service(:argu)
        .post(
          expand_uri_template(:favorites_iri, root_id: root_id),
          body: {iri: iri},
          headers: {accept: 'application/json'}
        )
    end

    def create_membership(token)
      group_iri = expand_uri_template(:groups_iri, id: token.group_id, root_id: token.root_id)
      service(:argu).post(
        collection_iri_path(group_iri, :group_memberships),
        body: {token: token.secret},
        headers: {accept: 'application/json'}
      )
    end

    def create_user(email, r: nil)
      response = service(:argu).post(
        expand_uri_template(:user_registration),
        body: {user: {email: email}, r: r},
        headers: {accept: 'application/json'}
      )
      update_user_token(response)
      user_from_response(response, email)
    rescue OAuth2::Error
      nil
    end

    def email_address_exists?(email)
      service(:argu, token: service_token)
        .get(expand_uri_template(:spi_email_addresses, email: email))
      true
    rescue OAuth2::Error
      false
    end

    def generate_guest_token(r: nil)
      result = service(:argu, token: service_token).post(
        expand_uri_template(:spi_oauth_token),
        body: {scope: :guest, r: r}
      )
      @user_token = JSON.parse(result.body)['access_token']
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

    private

    def parsed_cookies(response)
      cookies = {}
      response.headers['set-cookie']&.split(',')&.each do |cookie|
        split = cookie.strip.split(';')[0].strip.split('=')
        cookies[split[0]] = CGI.unescape(split[1])
      end
      cookies
    end

    def user_from_response(response, email)
      attributes = JSON.parse(response.body)
      attributes['included'] = [
        {attributes: {email: email, primary: true}}
          .merge(attributes.dig('data', 'relationships', 'emailAddresses', 'data').first)
      ]
      CurrentUser.from_response(user_token, User.new(attributes))
    end

    def set_argu_client_token_cookie(token, expires = nil)
      cookie_jar['argu_client_token'] = {
        expires: expires,
        value: token,
        secure: Rails.env.staging? || Rails.env.production?,
        httponly: true,
        domain: :all
      }
    end

    def update_user_token(response)
      set_argu_client_token_cookie(parsed_cookies(response)['argu_client_token'])
      @user_token = response.headers['new-authorization'] || cookie_jar.encrypted[:argu_client_token]
      Bugsnag.notify('No new user token received') if @user_token.blank?
    end
  end
end
