# frozen_string_literal: true

require_relative '../spec_helper'

describe Collection do
  subject { collection }

  let(:collection) do
    col = described_class.new(
      association: :resource,
      association_class: Record,
      filter: try(:filter),
      page: try(:page),
      parent: try(:parent)
    )
    col.define_singleton_method(:record_records_url) do |parent, protocol:|
      "#{protocol}://argu.test/resources/#{parent.try(:id) || parent}"
    end
    col.define_singleton_method(:records_url) do |protocol:|
      "#{protocol}://argu.test/resources"
    end
    col
  end

  describe '#id' do
    subject { collection.id }

    it { is_expected.to eq('https://argu.test/resources') }

    context 'with parent' do
      let(:parent) { Record.new({}) }

      it { is_expected.to eq('https://argu.test/resources/record_id') }
    end

    context 'with page' do
      let(:page) { 2 }

      it { is_expected.to eq('https://argu.test/resources?page=2') }
    end
  end

  describe '#parent_view_iri' do
    subject { collection.parent_view_iri }

    let(:filter) { {key: :value} }

    it { is_expected.to be_nil }

    context 'with parent' do
      let(:parent) { Record.new({}) }

      it { is_expected.to be_nil }
    end

    context 'with page' do
      let(:page) { 2 }
      let(:url) { 'https://argu.test/resources?filter%5Bkey%5D=value' }

      it { is_expected.to eq(url) }
    end
  end

  describe '#filter_query' do
    subject { collection.send(:filter_query) }

    it { is_expected.to be_nil }

    context 'with filters' do
      let(:filter) { {key: :value, key2: 'value2', key3: 'empty'} }
      let(:result) do
        [
          'actual_key = ? AND key2 = ? AND key3 IS NULL',
          'actual_value',
          'value2'
        ]
      end

      it { is_expected.to eq(result) }
    end
  end
end
