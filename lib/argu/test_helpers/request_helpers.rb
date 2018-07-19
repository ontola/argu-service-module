# frozen_string_literal: true

module Argu
  module TestHelpers
    module RequestHelpers
      include JsonApiHelper

      def expect_attributes(keys, index = nil)
        attrs = index.present? ? parsed_body.dig('data', index, 'attributes') : parsed_body.dig('data', 'attributes')
        expect(attrs.keys - keys.map(&:to_s)).to be_empty
      end

      def expect_data_size(n)
        expect(parsed_body['data'].size).to eq(n)
      end

      def expect_default_view
        @default_view ||= expect_included(expect_relationship('defaultView')['data']['id'])
      end

      def expect_error_message(msg, index = 0)
        expect(parsed_body['errors'][index]['message']).to eq(msg)
      end

      def expect_error_size(n)
        expect(parsed_body['errors'].size).to eq(n)
      end

      def expect_included(id)
        if id.is_a?(Array)
          expect(id).not_to be_empty, 'No entries given'
          id.map(&method(:expect_included))
        else
          included = json_api_included_resource(parsed_body, id: id.to_s)
          expect(included).to be_truthy,
                              "#{id} is not included. Only found #{parsed_body['included']&.map { |i| i['id'] }}"
          included
        end
      end

      def expect_not_included(id)
        if id.is_a?(Array)
          expect(id).not_to be_empty, 'No entries given'
          id.each { |single| expect_not_included(single) }
        else
          included = json_api_included_resource(parsed_body, id: id.to_s)
          expect(included).to be_nil, "#{id} is included"
          included
        end
      end

      def expect_no_relationship(key, parent: primary_resource)
        relationship = parent.dig('relationships', key)
        assert relationship.nil? || relationship['data'].nil? || relationship['data'].count.zero?
      end

      def expect_relationship(key, size: 1, parent: primary_resource)
        expect(size.positive?).to be_truthy
        relationship = parent.dig('relationships', key)
        expect(relationship).to be_truthy, "#{key} is not in relationships. Only found #{parent['relationships'].keys}"
        data = relationship['data']
        unless size == 1 && data.is_a?(Hash)
          count = data&.size || 0
          expect(count).to eq(size), "Expected size of relationship #{key} to equal #{size}, but was #{count}"
        end
        relationship
      end

      def expect_type(type)
        expect(primary_resource['type']).to eq(type)
      end

      def parsed_body
        JSON.parse(response.body).with_indifferent_access
      end

      def primary_resource
        parsed_body['data']
      end

      def expect_view_members(parent, count)
        member_sequence = expect_included(expect_relationship('memberSequence', size: 1, parent: parent)['data']['id'])
        ids = view_member_ids(member_sequence, count)
        expect_included(ids) unless count.zero?
      end

      def view_member_ids(parent, count)
        return expect_no_relationship('members', parent: parent) if count.zero?
        members = expect_relationship('members', parent: parent, size: count)
        members['data'].map { |m| m['id'] }
      end
    end
  end
end
