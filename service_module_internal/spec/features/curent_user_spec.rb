# frozen_string_literal: true
require_relative '../spec_helper'

describe 'Current user' do
  it 'should fetch current user' do
    stub_request(:get, 'https://argu.test/spi/current_user')
      .with(headers: {'Accept': 'application/vnd.api+json', 'Authorization': 'Bearer user_token_1'})
      .to_return(status: 200, body: mock_response(1))
    stub_request(:get, 'https://argu.test/spi/current_user')
      .with(headers: {'Accept': 'application/vnd.api+json', 'Authorization': 'Bearer user_token_2'})
      .to_return(status: 200, body: mock_response(2))

    resource = CurrentUser.find('user_token_1')
    expect(resource.id).to eq('user_1')
    expect(resource.display_name).to eq('user 1')
    resource = CurrentUser.find('user_token_2')
    expect(resource.id).to eq('user_2')
    expect(resource.display_name).to eq('user 2')
  end

  private

  def mock_response(id)
    {
      data: {
        id: "user_#{id}",
        type: 'users',
        attributes: {displayName: "user #{id}"}
      }
    }.to_json
  end
end
