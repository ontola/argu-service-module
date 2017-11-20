# frozen_string_literal: true

require_relative '../spec_helper'

describe ActionItem, type: :model do
  subject { action_item }

  let(:action_item) do
    described_class.new(target: target)
  end
  let(:target) { EntryPoint.new }

  it { is_expected.to be_valid }

  describe '#target' do
    context 'blank' do
      let(:target) { nil }

      it { expects_to_raise }
    end
  end

  def expects_to_raise
    rescued = false
    begin
      try(:subject)
    rescue RuntimeError
      rescued = true
    end
    expect(rescued).to be_truthy
  end
end
