# frozen_string_literal: true

require_relative '../spec_helper'

describe CurrentUser do
  let(:current_user) { described_class.from_token(token) }

  let(:token_1) { doorkeeper_token('user', id: 1) }
  let(:token_2) { doorkeeper_token('user', id: 2, language: :nl) }

  context 'with user 1' do
    let(:token) { token_1 }

    it 'gets id from token' do
      expect(current_user.id).to eq(1)
    end

    it 'gets language from token' do
      expect(current_user.language).to eq('en')
    end

    it 'fetches user for display_name' do
      user_mock
      expect(current_user.display_name).to eq('User1')
    end
  end

  context 'with user 2' do
    let(:token) { token_2 }

    it 'gets id from token' do
      expect(current_user.id).to eq(2)
    end

    it 'gets language from token' do
      expect(current_user.language).to eq('nl')
    end

    it 'fetches user for display_name' do
      user_mock(2)
      expect(current_user.display_name).to eq('User2')
    end
  end
end
