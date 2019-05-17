require 'faraday_middleware'
require 'logger'
require 'mrt/ingest'
require 'mysql2/client'
require 'oai/client'
require 'ostruct'
require 'pathname'
require 'time'
require 'yaml'

module Merritt
  module TIND
    class Harvester

      attr_reader :config

      def initialize(config)
        @config = config

        set_str = config.set ? "'#{config.set}'" : '<nil>'
        log.info("initializing harvester for base URL #{base_uri}, set #{set_str} => collection #{config.collection_ark}")
      end

      def process_feed!(from_time: nil, until_time: nil)
        from_time = determine_from_time(from_time)
        feed = harvest(from_time: from_time, until_time: until_time)
        feed.each do |r|
          record_processor = RecordProcessor.new(record: r, inv_db: inv_db, log: log)
          record_processor.process_record!
        end
      end

      def harvest(from_time: nil, until_time: nil)
        opts = to_opts(from_time, until_time)
        log.info("harvesting #{query_uri(opts)}")
        resp = client.list_records(opts)
        Feed.new(resp)
      end

      def base_uri
        @base_uri ||= URI.parse(config.base_url)
      end

      def last_harvest
        @last_harvest ||= LastHarvest.from_file(config.last_harvest_path)
      end

      def client
        @client ||= Harvester.oai_client_for(base_uri)
      end

      def inv_db
        @inv_db ||= InventoryDB.from_file(config.db_config_path)
      end

      def log
        @log ||= Logging.new_logger(config.log_path, config.log_level)
      end

      private

      def determine_from_time(from_time)
        return from_time if from_time

        oldest_failed = last_harvest.oldest_failed_datestamp
        return oldest_failed if oldest_failed

        last_harvest.newest_success_datestamp
      end

      def utc_or_nil(time)
        return time.utc if time.respond_to?(:utc)
        return unless time

        raise ArgumentError, "time #{time} does not appear to be a Time"
      end

      def query_uri(opts)
        query = '?ListRecords'
        opts.each { |k, v| query << "&#{k}=#{v}" } if opts
        base_uri.merge(query)
      end

      def to_opts(from_time, until_time)
        from_time, until_time = valid_range(from_time, until_time)
        {
          from: from_time && from_time.iso8601,
          until: until_time && until_time.iso8601,
          set: config.set
        }.compact
      end

      def valid_range(from_time, until_time)
        from_time, until_time = [from_time, until_time].map(&method(:utc_or_nil))
        if from_time && until_time
          raise RangeError, "from_time #{from_time} must be <= until_time #{until_time}" if from_time > until_time
        end

        [from_time, until_time]
      end

      class << self

        def from_file(config_yml)
          config = Config.from_file(config_yml)
          Harvester.new(config)
        end

        def oai_client_for(base_uri)
          # Workaround for https://github.com/code4lib/ruby-oai/issues/45
          http_client = Faraday.new(base_uri) do |conn|
            conn.request(:retry, max: 5, retry_statuses: 503)
            conn.response(:follow_redirects, limit: 5)
            conn.adapter(:net_http)
          end
          OAI::Client.new(base_uri.to_s, http: http_client)
        end

      end

    end
  end
end
