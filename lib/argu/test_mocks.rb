# frozen_string_literal: true

require_relative '../../../spec/support/test_root_id'

module TestMocks
  include UrlHelper

  def as_guest
    @bearer_token = 'guest'
    current_user_guest_mock
  end

  def as_guest_with_account(with_access_token = true)
    if with_access_token
      as_guest
    else
      current_user_guest_mock(token: '')
      generate_guest_token_mock
    end
    stub_request(:post, expand_service_url(:argu, '/users'))
      .with(headers: {'Authorization' => 'Bearer guest'})
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
    as_guest
    generate_guest_token_mock
    stub_request(:post, expand_service_url(:argu, '/users'))
      .with(headers: {'Authorization' => 'Bearer guest'})
      .to_return(
        status: 201,
        body: {
          data: user_data(1, email),
          included: user_included(1)
        }.to_json
      )
  end

  def as_user(id = 1, opts = {})
    @bearer_token = 'user'
    current_user_user_mock(id, opts)
  end

  def current_user_guest_mock(token: ' guest')
    stub_request(:get, expand_service_url(:argu, '/spi/current_user'))
      .with(headers: {'Authorization' => "Bearer#{token}"})
      .to_return(
        status: 401,
        headers: {'Content-Type' => 'application/json'}
      )
  end

  def current_user_user_mock(id = 1, email: nil, confirmed: true, secondary_emails: [])
    url = expand_service_url(:argu, '/spi/current_user')
    user_mock(id, email: email, confirmed: confirmed, secondary_emails: secondary_emails, url: url)
  end

  def generate_guest_token_mock
    stub_request(:post, expand_service_url(:argu, '/spi/oauth/token'))
      .to_return(
        status: 201,
        body: {access_token: 'guest'}.to_json
      )
  end

  def group_mock(id)
    stub_request(:get, expand_service_url(:argu, "/#{TEST_ROOT_ID}/g/#{id}"))
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'application/json'},
        body: {
          data: {
            id: id,
            type: 'groups',
            attributes: {
              display_name: "Group#{id}"
            },
            relationships: {
              organization: {
                data: {
                  id: 'https://argu.dev/o/2',
                  type: 'pages'
                },
                links: {
                  self: {
                    meta: {
                      '@type': 'schema:organization'
                    }
                  },
                  related: {
                    href: 'https://argu.dev/o/1',
                    meta: {
                      attributes: {
                        '@id': 'https://argu.dev/o/1',
                        '@type': 'schema:Organization',
                        '@context': {
                          schema: 'http://schema.org/',
                          title: 'schema:name'
                        },
                        title: 'Argu'
                      }
                    }
                  }
                }
              }
            }
          },
          included: [
            {
              id: 'https://argu.dev/o/2',
              type: 'pages',
              attributes: {
                '@type': 'schema:Organization',
                potentialAction: nil,
                displayName: 'Argu'
              },
              links: {
                self: 'https://argu.dev/o/2'
              }
            }
          ]
        }.to_json
      )
  end

  def not_found_mock(url)
    stub_request(:get, url).to_return(status: 404)
  end

  def user_mock(id = 1, opts = {}) # rubocop:disable Metrics/AbcSize
    opts[:confirmed] ||= true
    opts[:secondary_emails] ||= []
    opts[:token] ||= 'user'
    opts[:url] ||= mock_user_iri(id)
    opts[:email] ||= "user#{id}@example.com"
    stub_request(:get, opts[:url])
      .with(headers: {'Authorization' => "Bearer #{opts[:token]}"})
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'application/json'},
        body: {
          data: user_data(id, opts[:email], opts[:secondary_emails]),
          included: user_included(id, opts)
        }.to_json
      )
  end

  def create_membership_mock(opts = {})
    stub_request(:post, expand_service_url(:argu, "/#{TEST_ROOT_ID}/g/#{opts[:group_id]}/group_memberships"))
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
    stub_request(:post, expand_service_url(:argu, "/#{TEST_ROOT_ID}/favorites"))
      .with(body: {iri: opts[:iri]})
      .to_return(status: opts[:status] || 201)
  end

  def emails_mock(type, id, event = 'create')
    stub_request(
      :get,
      expand_service_url(:email, '/email/emails', event: event, resource_id: id, resource_type: type)
    ).to_return(status: 200, body: [].to_json)
  end

  def confirm_email_mock(email)
    stub_request(:put, expand_service_url(:argu, '/users/confirm'))
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
    stub_request(:get, expand_service_url(:argu, '/spi/authorize', params)).to_return(status: 200)
  end

  def unauthorized_mock(type: nil, id: nil, iri: nil, action: nil)
    params = {
      authorize_action: action,
      resource_id: id,
      resource_iri: iri,
      resource_type: type
    }.delete_if { |_k, v| v.nil? }
    stub_request(:get, expand_service_url(:argu, '/spi/authorize', params)).to_return(status: 403)
  end

  private

  def host_name
    Rails.application.config.host_name
  end

  def mock_user_iri(id)
    expand_service_url(:argu, "/u/#{id}")
  end

  def user_data(id, email, secondary_emails = [])
    {
      id: mock_user_iri(id),
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
        language: NS::ARGU['locale/en']
      },
      relationships: {
        defaultProfilePhoto: {
          data: {
            id: 'https://argu.dev/media_objects/1',
            type: 'http://schema.org/ImageObject'
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
        email_addresses: {
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

  def user_included(id, opts = {})
    included =
      [email: opts[:email], confirmed: opts[:confirmed]]
        .concat(opts[:secondary_emails] || [])
        .each_with_index
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
    included + [
      {
        id: 'https://argu.dev/media_objects/1',
        type: 'http://schema.org/ImageObject',
        attributes: {
          thumbnail: 'https://argu.dev/photo.png'
        }
      }
    ]
  end
end
