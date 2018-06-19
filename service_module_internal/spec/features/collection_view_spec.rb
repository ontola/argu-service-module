# frozen_string_literal: true

require_relative '../spec_helper'

describe CollectionView do
  subject { collection }

  let(:collection) do
    col = Collection.new(
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
    collection.send(:filtered_collection, a: 1, b: 2)
  end
  let(:paginated_collection_view) do
    collection.view_with_opts(type: :paginated, page: 1)
  end
  let(:infinite_collection_view) do
    collection.view_with_opts(type: :infinite, before: before_time)
  end
  let(:before_time) { Time.current.utc.to_s(:db) }
  let(:encoded_before_time) { ERB::Util.url_encode(before_time) }

  describe '#id' do
    context 'with paginated view' do
      subject { paginated_collection_view.id }

      it { is_expected.to eq('http://argu.test/resources?page=1&type=paginated') }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to eq('http://argu.test/r/record_id/resources?page=1&type=paginated') }
      end
    end

    context 'with infinite' do
      subject { infinite_collection_view.id }

      it { is_expected.to eq("http://argu.test/resources?type=infinite&before=#{encoded_before_time}") }

      context 'with parent' do
        let(:parent) { Record.new({}) }

        it { is_expected.to eq("http://argu.test/r/record_id/resources?type=infinite&before=#{encoded_before_time}") }
      end
    end
  end

  describe '#collection' do
    context 'with paginated' do
      subject { paginated_collection_view.collection }

      it { is_expected.to eq(collection) }
    end

    context 'with infinite' do
      subject { infinite_collection_view.collection }

      it { is_expected.to eq(collection) }
    end
  end
end
