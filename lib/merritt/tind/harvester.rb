require 'faraday_middleware'
require 'oai/client'
require 'yaml'
require 'logger'

module Merritt
  module TIND
    class Harvester

      attr_reader :config
      attr_reader :client

      def initialize(config)
        raise ArgumentError, 'config cannot be nil' unless config

        @config = config
        log.info("initializing harvester for base URL #{base_url}, set #{set ? "'#{set}'" : '<nil>'} => collection #{collection}")
        @client = Harvester.oai_client_for(base_url)
      end

      def harvest(from_time: nil, until_time: nil)
        opts = to_opts(from_time, until_time)
        log.info("harvesting #{query_url(opts)}")
        resp = client.list_records(opts)
        Feed.new(resp)
      end

      def set
        config.set
      end

      def base_url
        config.base_url
      end

      def collection
        config.collection
      end

      def log
        config.log
      end

      private

      def query_url(opts)
        query_url = base_url + '?ListRecords'
        return query_url unless opts && !opts.empty?

        opts.each { |k, v| query_url << "&#{k}=#{v}" }
        query_url
      end

      def to_opts(from_time, until_time)
        from_time, until_time = valid_range(from_time, until_time)
        {
          from: from_time && from_time.iso8601,
          until: until_time && until_time.iso8601,
          set: set
        }.compact
      end

      def valid_range(from_time, until_time)
        from_time, until_time = [from_time, until_time].map(&method(:utc_or_nil))
        if from_time && until_time
          raise RangeError, "from_time #{from_time} must be <= until_time #{until_time}" if from_time > until_time
        end

        [from_time, until_time]
      end

      def utc_or_nil(time)
        return time.utc if time.respond_to?(:utc)
        return unless time

        raise ArgumentError, "time #{time} does not appear to be a Time"
      end

      class << self

        def oai_client_for(base_url)
          # Workaround for https://github.com/code4lib/ruby-oai/issues/45
          http_client = Faraday.new(URI.parse(base_url)) do |conn|
            conn.request(:retry, max: 5, retry_statuses: 503)
            conn.response(:follow_redirects, limit: 5)
            conn.adapter(:net_http)
          end
          OAI::Client.new(base_url, http: http_client)
        end

      end
    end
  end
end
