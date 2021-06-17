# frozen_string_literal: true

module Argu
  class Cache
    SLICE_SIZE = 20
    extend ServiceHelper

    class << self
      def invalidate_all
        response = service(:cache, token: nil).get('link-lib/cache/clear')

        raise("Wrong response for clearing cache (#{response.status}): #{response.body}") unless response.body == 'OK'
      end

      def warm
        Rails.application.eager_load!

        Apartment::Tenant.each do
          Page.find_each do |page|
            Warmer.warm(page)
          end
        end
      end
    end

    class Warmer # rubocop:disable Metrics/ClassLength
      class << self
        def warm(page)
          ActsAsTenant.with_tenant(page) do
            warm_iris(page.iri, collect_iris)
          end
        end

        private

        def bulk_request(iris, website)
          iris.each_slice(SLICE_SIZE).flat_map do |resources|
            # rubocop:disable Rails/Output
            $stdout.write '*'
            party = bulk_request_batch(resources, website)

            $stdout.write "\b." if party.response.code == '200'

            if party.response.code != '200'
              $stdout.write "\be"
              "Received status #{party.response.code} on resources [#{resources.join(', ')}]"
            end
            # rubocop:enable Rails/Output
          end
        end

        def bulk_request_batch(resources, website)
          url = 'http://cache.svc.cluster.local:3030/link-lib/bulk'
          opts = {
            body: {resource: resources},
            headers: bulk_request_headers(website)
          }

          HTTParty.post(url, opts)
        end

        def bulk_request_headers(website)
          {
            'Accept-Language': 'en',
            'Website-IRI': website.to_s,
            'X-Forwarded-Host': website.host,
            'X-Forwarded-Proto': 'https',
            'X-Forwarded-Ssl': 'on'
          }
        end

        def collect_iris
          static_iris + form_iris + dynamic_iris
        end

        def dynamic_iris
          Rails.logger.info("Collecting IRIs for website #{ActsAsTenant.current_tenant.iri}")

          objects = Edge.all.flat_map { |o| traverse(o, o.class.show_includes, :show_includes) }
          objects
            .map { |o| o&.try(:iri) }
            .filter { |o| o.is_a?(RDF::URI) }
        end

        def form_iris
          Rails.logger.info('Collecting form IRIs')

          LinkedRails::Form
            .descendants
            .map do |klass|
            klass.new.iri
          end
        end

        def resolve_array(obj, include, deep_includes)
          include.uniq.flat_map do |i|
            include_map = deep_includes ? i.class.try(deep_includes) : i
            traverse(obj, include_map || i)
          end
        end

        def resolve_collection_value(obj, include, deep_includes)
          return unless obj.is_a?(Collection)

          obj.parent.send(obj.association).all.flat_map do |member|
            include_map = deep_includes ? member.class.try(deep_includes) : include
            traverse(member, include_map || include)
          end
        rescue StandardError => e
          Rails.logger.warn("Caught error: #{e}")
        end

        def resolve_hash(obj, include, deep_includes)
          include.flat_map do |k, v|
            nested_obj = obj.try(k)
            include_map = deep_includes ? nested_obj.class.try(deep_includes) : v
            traverse(nested_obj, include_map || v)
          rescue StandardError => e
            Rails.logger.warn("Caught error: #{e}")
          end
        end

        def resolve_path(obj, include)
          include.to_s.split('.').reduce([obj]) { |objs, prop| objs + [objs.try(prop)] }
        rescue StandardError => e
          Rails.logger.warn("Caught error: #{e}, include: #{include.class.name}(#{include})")
        end

        def resolve_value(obj, include, deep_includes) # rubocop:disable Metrics/MethodLength
          if include.is_a?(Symbol) || include.is_a?(String)
            resolve_path(obj, include)
          elsif include.is_a?(Array)
            resolve_array(obj, include, deep_includes)
          elsif include.is_a?(Hash)
            resolve_hash(obj, include, deep_includes)
          elsif include.nil?
            nil
          else
            throw "Unexpected include type '#{include.class.name}' (value was: #{include})"
          end
        end

        def static_iris
          [
            Ontology.new.iri
          ]
        end

        def traverse(obj, include, deep_includes = nil)
          return unless obj

          result = resolve_value(obj, include, deep_includes)
          nested = resolve_collection_value(obj, include, deep_includes)

          [
            obj,
            result,
            nested
          ].flatten.compact.uniq
        end

        def warm_iris(website, iris) # rubocop:disable Metrics/AbcSize
          Rails.logger.info(
            "Warming up to #{iris.length} resources for website #{website} in #{(iris.length / SLICE_SIZE).ceil} steps"
          )
          # rubocop:disable Rails/Output
          $stdout.write '['
          errors = bulk_request(iris, website)
          $stdout.write "]\n"
          # rubocop:enable Rails/Output

          raise("Errors while warming: #{errors.compact.join("\n")}") if errors.compact.present?

          Rails.logger.info('Finished warming cache')
        end
      end
    end
  end
end
