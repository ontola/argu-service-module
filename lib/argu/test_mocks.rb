# frozen_string_literal: true

require_relative '../../spec/support/test_root_id'

module TestMocks
  include JWTHelper
  include UrlHelper
  include UriTemplateHelper

  def as_guest
    @bearer_token = doorkeeper_token('guest')
  end

  def as_service
    @bearer_token = doorkeeper_token('service')
  end

  def as_guest_with_account(with_access_token = true)
    token = with_access_token ? as_guest : generate_guest_token_mock
    stub_request(:post, expand_service_url(:argu, '/argu/users'))
      .with(headers: {'Authorization' => "Bearer #{token}"})
      .to_return(
        status: 422,
        body: {
          code: 'VALUE_TAKEN',
          message: 'Email has already been taken',
          notifications: [
            {
              type: 'error',
              message: 'Email has already been taken'
            }
          ]
        }.to_json
      )
  end

  def as_guest_without_account(email)
    token = generate_guest_token_mock
    stub_request(:post, expand_service_url(:argu, '/argu/users'))
      .with(headers: {'Authorization' => "Bearer #{token}"})
      .to_return(
        status: 201,
        body: {
          data: user_data(1, email)
        }.to_json,
        headers: {'New-Authorization' => doorkeeper_token('user')}
      )
  end

  def as_user(id = 1, opts = {})
    @bearer_token = doorkeeper_token('user', id: id)
    user_mock(id, opts)
  end

  def find_tenant_mock(iri = 'www.example.com\/argu\/(tokens|email|spi).*')
    stub_request(
      :get,
      /#{expand_service_url(:argu, '/_public/spi/find_tenant')}\?iri=#{iri}/
    ).to_return(
      status: 200,
      body: {
        iri_prefix: "app.#{ENV['HOSTNAME']}/argu",
        uuid: TEST_ROOT_ID,
        accent_background_color: '#475668',
        accent_color: '#FFFFFF',
        navbar_background: '#475668',
        navbar_color: '#FFFFFF',
        database_schema: 'argu',
        use_new_frontend: false
      }.to_json
    )
  end

  def generate_guest_token_mock
    token = doorkeeper_token('guest')
    stub_request(:post, expand_service_url(:argu, '/argu/spi/oauth/token'))
      .to_return(
        status: 201,
        body: {access_token: token}.to_json
      )
    token
  end

  def user_mock(id = 1, opts = {}) # rubocop:disable Metrics/AbcSize
    opts[:confirmed] ||= true
    opts[:secondary_emails] ||= []
    opts[:token] ||= ENV['SERVICE_TOKEN']
    opts[:url] ||= expand_service_url(:argu, "/argu/u/#{id}")
    opts[:email] ||= "user#{id}@email.com"
    headers = {'Accept': 'application/vnd.api+json'}
    headers['Authorization'] = "Bearer #{opts[:token]}" if opts[:token]
    stub_request(:get, opts[:url])
      .with(headers: headers)
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'application/json'},
        body: {
          data: user_data(id, opts[:email], opts[:language], opts[:secondary_emails]),
          included:
            included_emails(id, [email: opts[:email], confirmed: opts[:confirmed]] + opts[:secondary_emails])
              .append(included_profile_photo)
        }.to_json
      )
  end

  def create_membership_mock(opts = {})
    stub_request(:post, expand_service_url(:argu, "/argu/g/#{opts[:group_id]}/group_memberships"))
      .with(
        body: {
          token: opts[:secret]
        }
      )
      .to_return(
        status: opts[:response] || 201,
        headers: {location: argu_url('/group_memberships/1')},
        body: {
          data: {
            id: 1,
            type: 'group_memberships',
            attributes: {
            },
            relationships: {
              group: {
                data: {
                  id: 1,
                  type: 'groups'
                }
              }
            }
          },
          included: [
            {
              id: 1,
              type: 'groups',
              attributes: {
                displayName: 'group_name'
              }
            }
          ]
        }.to_json
      )
  end

  def create_favorite_mock(opts = {})
    stub_request(:post, expand_service_url(:argu, '/argu/favorites'))
      .with(body: {iri: opts[:iri]})
      .to_return(status: opts[:status] || 201)
  end

  def emails_mock(type, id, event = 'create')
    stub_request(
      :get,
      expand_service_url(:email, '/argu/email/emails', event: event, resource_id: id, resource_type: type)
    ).to_return(status: 200, body: [].to_json)
  end

  def email_check_mock(email, exists)
    stub_request(:get, expand_service_url(:argu, '/argu/spi/email_addresses', email: email))
      .to_return(status: exists ? 200 : 404)
  end

  def group_mock(id)
    stub_request(
      :get,
      expand_service_url(:argu, ['/argu', :g, id].compact.join('/'))
    ).to_return(
      status: 200,
      body: {
        data: {
          id: 1,
          type: 'groups',
          attributes: {
            iri: argu_url('/argu/g/1'),
            display_name: "Group#{id}"
          },
          relationships: {
            organization: {
              data: {
                id: 1,
                type: 'organizations'
              }
            }
          }
        },
        included: [
          {
            id: 1,
            type: 'organizations',
            attributes: {
              displayName: 'Organization Name',
              iri: argu_url('/argu')
            }
          }
        ]
      }.to_json
    )
  end

  def confirm_email_mock(email)
    stub_request(:put, expand_service_url(:argu, '/argu/users/confirm'))
      .with(body: {email: email}, headers: {'Accept' => 'application/json'})
      .to_return(status: 200)
  end

  def authorized_mock(type: nil, id: nil, iri: nil, action: nil)
    params = {
      authorize_action: action,
      resource_id: id,
      resource_iri: iri,
      resource_type: type
    }.delete_if { |_k, v| v.nil? }
    stub_request(:get, expand_service_url(:argu, '/argu/spi/authorize', params)).to_return(status: 200)
  end

  def unauthorized_mock(type: nil, id: nil, iri: nil, action: nil)
    params = {
      authorize_action: action,
      resource_id: id,
      resource_iri: iri,
      resource_type: type
    }.delete_if { |_k, v| v.nil? }
    stub_request(:get, expand_service_url(:argu, '/argu/spi/authorize', params)).to_return(status: 403)
  end

  def not_found_mock(url)
    stub_request(:get, url).to_return(status: 404)
  end

  private

  def doorkeeper_token(type, id: SecureRandom.hex, email: nil, language: :en, exp: 1.hour.from_now)
    registered = type == 'user'
    sign_payload(
      exp: exp.to_i,
      iat: Time.current.iso8601(5),
      scopes: use_legacy_frontend? ? [type] : [type, :afe],
      user: {
        type: type,
        '@id': expand_uri_template("#{registered ? :users : :guest_users}_iri", id: 1, with_hostname: true),
        id: id,
        email: registered && (email || "user#{id}@email.com"),
        language: language
      }
    )
  end

  def host_name
    Rails.application.config.host_name
  end

  def included_emails(id, emails)
    emails.each_with_index
      .map do |e, i|
      {
        id: "https://argu.dev/u/#{id}/email/#{i}",
        type: 'emailAddresses',
        attributes: {
          '@type' => 'argu:Email',
          email: e[:email],
          primary: i.zero?,
          confirmedAt: e[:confirmed] ? Time.current : nil
        }
      }
    end
  end

  def included_profile_photo(id = '1')
    {
      id: id,
      type: 'photos',
      attributes: {
        thumbnail: nil
      }
    }
  end

  def user_data(id, email, language = NS::ARGU['locale/en'], secondary_emails = [])
    {
      id: NS::ARGU["u/#{id}"],
      type: 'users',
      attributes: {
        '@context': {
          schema: 'http://schema.org/',
          hydra: 'http://www.w3.org/ns/hydra/core#',
          argu: 'https://argu.co/ns/core#',
          createdAt: 'http://schema.org/dateCreated',
          updatedAt: 'http://schema.org/dateModified',
          displayName: 'schema:name',
          about: 'schema:description',
          '@vocab': 'http://schema.org/'
        },
        '@type': 'schema:Person',
        potentialAction: nil,
        displayName: "User#{id}",
        about: '',
        url: "user#{id}",
        email: email,
        language: language
      },
      relationships: {
        defaultProfilePhoto: {
          data: {
            id: '1',
            type: 'photos'
          },
          links: {
            self: {
              meta: {'@type': 'http://schema.org/image'}
            },
            related: {
              href: 'https://argu.dev/photos/1',
              meta: {'@type': 'http://schema.org/ImageObject'}
            }
          }
        },
        emailAddresses: {
          data: Array.new((secondary_emails.count + 1)) do |i|
            {id: "https://argu.dev/u/#{id}/email/#{i}", type: 'emailAddresses'}
          end
        }
      },
      links: {
        self: "https://argu.dev/u/#{id}"
      }
    }
  end
end
