# frozen_string_literal: true

require_relative '../spec_helper'

describe ActionItem, type: :model do
  subject { action_item }

  let(:action_item) do
    described_class.new
  end

  it { is_expected.to be_valid }
end
