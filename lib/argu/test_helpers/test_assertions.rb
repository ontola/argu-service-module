# frozen_string_literal: true

module Argu
  module TestHelpers
    module TestAssertions
      def requested_iri
        RDF::URI(request.original_url.sub(".#{request.format.symbol}", ''))
      end

      def assert_disabled_form(iri: requested_iri, error: 'This action is currently not available')
        assert_response 200
        expect_triple(iri, NS.schema.actionStatus, NS.ontola[:DisabledActionStatus])
        expect_triple(iri, NS.schema.error, error) if error
      end

      def assert_enabled_form(iri: requested_iri)
        assert_response 200
        expect_triple(iri, NS.schema.actionStatus, NS.schema.PotentialActionStatus)
      end

      def assert_not_a_user
        assert_response 401
      end

      def assert_not_authorized
        assert_response 403
      end

      def assert_email_sent(count: 1, skip_sidekiq: false, root: :argu) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        unless skip_sidekiq
          assert_equal count, Sidekiq::Worker.jobs.select { |j| j['class'] == 'SendEmailWorker' }.count
          SendEmailWorker.drain
        end

        assert_requested :post, expand_service_url(:email, "/#{root}/email/spi/emails"), times: count
        last_match = WebMock::RequestRegistry
                       .instance
                       .requested_signatures
                       .hash
                       .keys
                       .detect { |r| r.uri.to_s == expand_service_url(:email, "/#{root}/email/spi/emails") }
        WebMock.reset!
        last_match
      end

      def assert_redis_resource_count(count, **opts)
        assert_equal count, RedisResource::Relation.where(**opts).count
      end

      def expect_ontola_action(redirect: nil, snackbar: nil, reload: nil)
        if redirect
          query = {location: redirect, reload: reload}.compact.to_param.gsub('+', '%20')
          expect_exec_header("actions/redirect?#{query}")
        end
        expect_exec_header("actions/snackbar?#{{text: snackbar}.to_param.gsub('+', '%20')}") if snackbar

        expect_ontola_action_count([redirect, snackbar].compact.size)
      end

      def expect_ontola_action_count(count)
        if count.zero?
          assert_nil response.headers['Exec-Action']
        else
          assert_equal count, response.headers['Exec-Action'].count("\n"), response.headers['Exec-Action']
        end
      end

      def expect_header(key, value)
        expect(response.headers[key]).to(include(value))
      end

      def expect_exec_header(value)
        expect_header('Exec-Action', value)
      end

      def expect_errors(iri, errors)
        error_response = expect_triple(iri, NS.ll[:errorResponse], nil).first.object
        assert_equal expect_triple(error_response, nil, nil).count, errors.count + 2
        errors.each do |key, value|
          expect_triple(error_response, key, value)
        end
      end

      # Tests if the property {path} starting at {start} resolves to {value}.
      # If multiple solutions are present only one has to match to pass.
      #
      # @param [IRI] start The node to start at
      # @param [Array] path The property path to traverse
      # @param [IRI|IRI[]] value The value to match at the end, pass an array to
      #                            match multiple values.
      def expect_path(start, path, value) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        match = path.each_with_index.reduce(start) do |node, (path_seg, i)|
          obj = [*node].map { |cur_node| rdf_body.query([cur_node, path_seg, nil, nil]).map(&:object) }.flatten
          break (obj & [*value]).present? if path.length - 1 == i

          nodes = obj.filter { |o| o.is_a?(RDF::Resource) }
          break false if nodes.blank?

          nodes
        end

        segs = path.map(&:to_s).join(', ')
        assert match,
               "Expected to find '#{value}' from '#{start}' through '[#{segs}]' in\n#{response.body}"
      end

      def expect_resource_type(type, iri: requested_iri)
        expect_triple(iri, RDF[:type], type)
      end

      def expect_triple(subject, predicate, object, graph = NS.ld[:supplant])
        statement = RDF::Statement(subject, predicate, object, graph_name: graph)
        match = rdf_body.query(statement)
        assert match.present?, "Expected to find #{statement} in\n#{response.body}"
        match
      end

      def refute_triple(subject, predicate, object, graph = nil)
        statement = RDF::Statement(subject, predicate, object, graph_name: graph)
        refute rdf_body.query([subject, predicate, object, graph]).present?,
               "Expected not to find #{statement} in\n#{response.body}"
      end

      def expect_sequence(subject, predicate)
        expect_triple(subject, predicate, nil).first.object
      end

      def expect_sequence_member(subject, index, object)
        expect_triple(subject, RDF[:"_#{index}"], object)
        object
      end

      def expect_sequence_size(subject, expected_count)
        count =
          expect_triple(subject, nil, nil)
            .select { |s| s.predicate.to_s.starts_with?('http://www.w3.org/1999/02/22-rdf-syntax-ns#_') }
            .count
        assert_equal expected_count, count
      end

      def rdf_body
        @rdf_body ||= RDF::Graph.new << RDF::Reader
                                          .for(content_type: response.headers['Content-Type'])
                                          .new(response.body)
      end
    end
  end
end
