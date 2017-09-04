# frozen_string_literal: true

require_relative '../spec_helper'

describe CurrentUser do
  context 'user 1' do
    subject { described_class.find('user_token_1') }

    it 'has proper attributes' do
      is_expected.to have_attributes(
        id: 'user_1',
        display_name: 'user 1'
      )
    end
  end

  context 'user 2' do
    subject { described_class.find('user_token_2') }

    it 'has proper attributes' do
      is_expected.to have_attributes(
        id: 'user_2',
        display_name: 'user 2'
      )
    end
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

  before do
    stub_request(:get, 'https://argu.test/spi/current_user')
      .with(headers: {'Accept': 'application/vnd.api+json', 'Authorization': 'Bearer user_token_1'})
      .to_return(status: 200, body: mock_response(1))
    stub_request(:get, 'https://argu.test/spi/current_user')
      .with(headers: {'Accept': 'application/vnd.api+json', 'Authorization': 'Bearer user_token_2'})
      .to_return(status: 200, body: mock_response(2))
  end
end
