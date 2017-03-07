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

      def expect_error_message(msg, index = 0)
        expect(parsed_body['errors'][index]['message']).to eq(msg)
      end

      def expect_error_size(n)
        expect(parsed_body['errors'].size).to eq(n)
      end

      def expect_included(id)
        if id.is_a?(Array)
          expect(id).to be_truthy, 'No entries given'
          id.each { |single| expect_included(single) }
        else
          included = json_api_included_resource(parsed_body, id: id.to_s)
          expect(included).to be_truthy, "#{id} is not included"
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

      def expect_relationship(key, size = 1)
        relationship = parsed_body.dig('data', 'relationships', key)
        expect(relationship).to be_truthy, "#{key} is not in relationships"
        unless size == 1 && relationship['data'].is_a?(Hash)
          expect(relationship['data']&.size || 0).to eq(size), 'Size of relationship is incorrect'
        end
        relationship
      end

      def expect_type(type)
        expect(parsed_body['data']['type']).to eq(type)
      end

      def parsed_body
        @json ||= JSON.parse(response.body)
      end
    end
  end
end
