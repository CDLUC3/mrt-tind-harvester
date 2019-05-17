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

        set_str = config.oai_set ? "'#{config.oai_set}'" : '<nil>'
        log.info("initializing harvester for base URL #{oai_base_uri}, set #{set_str} => collection #{config.mrt_collection_ark}")
      end

      def process_feed!(from_time: nil, until_time: nil)
        from_time = determine_from_time(from_time)
        feed = harvest(from_time: from_time, until_time: until_time)
        feed.each do |r|
          record_processor = RecordProcessor.new(r, self)
          record_processor.process_record!
        end
      end

      def harvest(from_time: nil, until_time: nil)
        opts = to_opts(from_time, until_time)
        log.info("harvesting #{query_uri(opts)}")
        resp = oai_client.list_records(opts)
        Feed.new(resp)
      end

      def last_harvest
        @last_harvest ||= LastHarvest.from_file(config.last_harvest_path)
      end

      def oai_client
        @oai_client ||= Harvester.oai_client_for(oai_base_uri)
      end

      def oai_base_uri
        @oai_base_uri ||= URI.parse(config.oai_base_url)
      end

      def mrt_collection_ark
        config.mrt_collection_ark
      end

      def mrt_inv_db
        @mrt_inv_db ||= InventoryDB.from_file(config.db_config_path)
      end

      def log
        @log ||= Logging.new_logger(config.log_path, config.log_level)
      end

      def determine_from_time(from_time = nil)
        return from_time if from_time

        oldest_failed = last_harvest.oldest_failed_datestamp
        return oldest_failed if oldest_failed

        last_harvest.newest_success_datestamp
      end

      private

      def utc_or_nil(time)
        return time.utc if time.respond_to?(:utc)
        return unless time

        raise ArgumentError, "time #{time} does not appear to be a Time"
      end

      def query_uri(opts)
        query = '?ListRecords'
        opts.each { |k, v| query << "&#{k}=#{v}" } if opts
        oai_base_uri.merge(query)
      end

      def to_opts(from_time, until_time)
        from_time, until_time = valid_range(from_time, until_time)
        {
          from: from_time && from_time.iso8601,
          until: until_time && until_time.iso8601,
          set: config.oai_set
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
