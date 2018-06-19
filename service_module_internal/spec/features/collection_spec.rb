# frozen_string_literal: true

require_relative '../spec_helper'

describe Collection do
  subject { collection }

  let(:collection) do
    col = described_class.new(
      name: :records,
      association: :resource,
      association_class: Record,
      filter: try(:filter),
      parent: try(:parent),
      user_context: UserContext.new
    )
    col
  end
  let(:filtered_collection) do
    collection.send(:new_child, filter: {key: :value, key2: 'value2', key3: 'empty'})
  end

  describe '#id' do
    context 'with collection' do
      subject { collection.id }

      it { is_expected.to eq('http://argu.test/resources') }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to eq('http://argu.test/r/record_id/resources') }
      end
    end

    context 'with filtered collection' do
      subject { filtered_collection.id }

      let(:filter_string) { 'filter%5B%5D=key%3Dvalue&filter%5B%5D=key2%3Dvalue2&filter%5B%5D=key3%3Dempty' }

      it { is_expected.to eq("http://argu.test/resources?#{filter_string}") }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to eq("http://argu.test/r/record_id/resources?#{filter_string}") }
      end
    end
  end

  describe '#unfiltered_collection' do
    context 'with filtered collection' do
      subject { filtered_collection.unfiltered_collection }

      it { is_expected.to eq(collection) }
    end
  end

  describe '#apply_filter' do
    subject { collection.send(:apply_filters, Record.all).to_sql }

    let(:result) { 'SELECT "records".* FROM "records"' }

    it { is_expected.to eq(result) }

    context 'with filters' do
      subject { filtered_collection.send(:apply_filters, Record.all).to_sql }

      let(:result) do
        'SELECT "records".* FROM "records" WHERE '\
        '"records"."actual_key" = \'actual_value\' AND "records"."key2" = \'value2\' AND "records"."key3" IS NULL'
      end

      it { is_expected.to eq(result) }
    end
  end
end
