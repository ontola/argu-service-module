# frozen_string_literal: true

require 'oauth2'

module Argu
  class API
    include UriTemplateHelper
    attr_accessor :service_token, :user_token
    attr_reader :cookie_jar

    def initialize(service_token: nil, user_token: nil, cookie_jar: nil)
      @service_token = OAuth2::AccessToken.new(argu_client, service_token)
      @user_token = OAuth2::AccessToken.new(argu_client, user_token)
      @cookie_jar = cookie_jar
    end

    def authorize_action(resource_type, resource_id, action)
      user_token.get(
        uri_template(:spi_authorize)
          .expand(resource_type: resource_type, resource_id: resource_id, authorize_action: action)
      )
    end

    def authorize_redirect_resource(token)
      return unless token&.redirect_url
      authorize_url = uri_template(:spi_authorize).expand(
        resource_iri: token.redirect_url,
        authorize_action: :show
      )
      user_token.get(authorize_url).status == 200
    rescue OAuth2::Error
      false
    end

    def confirm_email_address(email)
      service_token.put(
        expand_uri_template(:user_confirm),
        body: {email: email},
        headers: {accept: 'application/json'}
      )
    end

    def create_email(mailer, template, recipient, options = {})
      recipient = recipient.slice(:display_name, :email, :language, :id)
      service_token.post(
        expand_uri_template(:email_spi_create),
        body: {email: {mailer: mailer, template: template, recipient: recipient, options: options}},
        headers: {accept: 'application/json'}
      )
    end

    def create_membership(token, user)
      user_token.post(
        "/g/#{token.group_id}/memberships",
        body: {shortname: user.url, token: token.secret},
        headers: {accept: 'application/json'}
      )
    end

    def create_user(email)
      response = user_token.post(
        expand_uri_template(:user_registration),
        body: {user: {email: email}},
        headers: {accept: 'application/json'}
      )
      set_argu_client_token_cookie(parsed_cookies(response)['argu_client_token'])
      self.user_token = OAuth2::AccessToken.new(user_token.client, cookie_jar.encrypted[:argu_client_token])
      user_from_response(response, email)
    rescue OAuth2::Error
      nil
    end

    def user_is_group_member?(group_id)
      user_token.get(
        expand_uri_template(
          :spi_authorize,
          resource_type: 'Group',
          resource_id: group_id,
          authorize_action: 'is_member'
        )
      )
    rescue OAuth2::Error => e
      [401, 403].include?(e.response.status) ? false : handle_oauth_error(e)
    end

    private

    def argu_client
      @argu_client ||= OAuth2::Client.new(ENV['ARGU_APP_ID'], ENV['ARGU_APP_SECRET'], site: ENV['OAUTH_URL'])
    end

    def parsed_cookies(response)
      cookies = {}
      response.headers['set-cookie']&.split(',')&.each do |cookie|
        split = cookie.strip.split(';')[0].strip.split('=')
        cookies[split[0]] = CGI.unescape(split[1])
      end
      cookies
    end

    def user_from_response(response, email)
      user = CurrentUser.instantiate_record(JSON.parse(response.body))
      user.attributes['email'] = email
      user.attributes['email_addresses'] = [
        OpenStruct.new(attributes: {email: email, primary: true}.with_indifferent_access)
      ]
      user
    end

    def set_argu_client_token_cookie(token, expires = nil)
      cookie_jar['argu_client_token'] = {
        expires: expires,
        value: token,
        secure: Rails.env.production?,
        httponly: true,
        domain: :all
      }
    end
  end
end
