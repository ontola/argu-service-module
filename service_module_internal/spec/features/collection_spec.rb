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
  let(:paginated_collection) do
    col = collection
    col.type = :paginated
    col
  end
  let(:infinite_collection) do
    col = collection
    col.type = :infinite
    col
  end

  describe '#id' do
    context 'paginated' do
      subject { paginated_collection.id }

      it { is_expected.to eq('https://argu.test/resources?type=paginated') }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to eq('https://argu.test/resources/record_id?type=paginated') }
      end

      context 'with page' do
        let(:page) { 2 }

        it { is_expected.to eq('https://argu.test/resources?page=2&type=paginated') }
      end
    end

    context 'infinite' do
      subject { infinite_collection.id }

      it { is_expected.to eq('https://argu.test/resources?type=infinite') }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to eq('https://argu.test/resources/record_id?type=infinite') }
      end

      context 'with page' do
        let(:page) { 2 }

        it { is_expected.to eq('https://argu.test/resources?page=2&type=infinite') }
      end
    end
  end

  describe '#parent_view_iri' do
    let(:filter) { {key: :value} }

    context 'paginated' do
      subject { paginated_collection.parent_view_iri }

      it { is_expected.to be_nil }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to be_nil }
      end

      context 'with page' do
        let(:page) { 2 }
        let(:url) { 'https://argu.test/resources?filter%5Bkey%5D=value&type=paginated' }

        it { is_expected.to eq(url) }
      end
    end

    context 'infinite' do
      subject { infinite_collection.parent_view_iri }

      it { is_expected.to be_nil }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to be_nil }
      end

      context 'with page' do
        let(:page) { 2 }
        let(:url) { 'https://argu.test/resources?filter%5Bkey%5D=value&type=infinite' }

        it { is_expected.to eq(url) }
      end
    end
  end

  describe '#filter_query' do
    context 'paginated' do
      subject { paginated_collection.send(:filter_query) }

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

    context 'infinite' do
      subject { infinite_collection.send(:filter_query) }

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
end
