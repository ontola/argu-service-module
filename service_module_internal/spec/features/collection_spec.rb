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
    context 'with paginated' do
      subject { paginated_collection.id }

      it { is_expected.to eq('http://argu.test/resources?type=paginated') }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to eq('http://argu.test/r/record_id/resources?type=paginated') }
      end

      context 'with page' do
        let(:page) { 2 }

        it { is_expected.to eq('http://argu.test/resources?page=2&type=paginated') }
      end
    end

    context 'with infinite' do
      subject { infinite_collection.id }

      it { is_expected.to eq('http://argu.test/resources?type=infinite') }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to eq('http://argu.test/r/record_id/resources?type=infinite') }
      end

      context 'with page' do
        let(:page) { 2 }

        it { is_expected.to eq('http://argu.test/resources?page=2&type=infinite') }
      end
    end
  end

  describe '#parent_view_iri' do
    let(:filter) { {key: :value} }

    context 'with paginated' do
      subject { paginated_collection.parent_view_iri }

      it { is_expected.to be_nil }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to be_nil }
      end

      context 'with page' do
        let(:page) { 2 }
        let(:url) { 'http://argu.test/resources?filter%5Bkey%5D=value&type=paginated' }

        it { is_expected.to eq(url) }
      end
    end

    context 'with infinite' do
      subject { infinite_collection.parent_view_iri }

      it { is_expected.to be_nil }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to be_nil }
      end

      context 'with page' do
        let(:page) { 2 }
        let(:url) { 'http://argu.test/resources?filter%5Bkey%5D=value&type=infinite' }

        it { is_expected.to eq(url) }
      end
    end
  end

  describe '#apply_filter' do
    let(:result) { 'SELECT "records".* FROM "records"' }

    context 'with paginated' do
      subject { paginated_collection.send(:apply_filters, Record.all).to_sql }

      it { is_expected.to eq(result) }

      context 'with filters' do
        let(:filter) { {key: :value, key2: 'value2', key3: 'empty'} }
        let(:result) do
          'SELECT "records".* FROM "records" WHERE '\
          '"records"."actual_key" = \'actual_value\' AND "records"."key2" = \'value2\' AND "records"."key3" IS NULL'
        end

        it { is_expected.to eq(result) }
      end
    end

    context 'with infinite' do
      subject { infinite_collection.send(:apply_filters, Record.all).to_sql }

      it { is_expected.to eq(result) }

      context 'with filters' do
        let(:filter) { {key: :value, key2: 'value2', key3: 'empty'} }
        let(:result) do
          'SELECT "records".* FROM "records" WHERE '\
          '"records"."actual_key" = \'actual_value\' AND "records"."key2" = \'value2\' AND "records"."key3" IS NULL'
        end

        it { is_expected.to eq(result) }
      end
    end
  end
end
