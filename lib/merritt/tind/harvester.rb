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

      def initialize(config, dry_run: false)
        @config = config
        @dry_run = dry_run

        set_str = config.oai_set ? "'#{config.oai_set}'" : '<nil>'
        log.info("Initializing harvester for base URL #{oai_base_uri}, set #{set_str} => collection #{config.mrt_collection_ark}")
      end

      def process_feed!(from_time: nil, until_time: nil)
        from_time = determine_from_time(from_time)
        feed = harvest(from_time: from_time, until_time: until_time)
        return process_feed(feed, nil) if dry_run?

        with_server { |server| process_feed(feed, server) }
      end

      def with_server
        server = Mrt::Ingest::OneTimeServer.new
        server.start_server
        yield
      ensure
        server.join_server
      end

      def harvest(from_time: nil, until_time: nil)
        opts = to_oai_opts(from_time, until_time)
        log.info("harvesting #{query_uri(opts)}")
        resp = oai_client.list_records(opts)
        Feed.new(resp)
      end

      def dry_run?
        @dry_run
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

      def mrt_ingest_profile
        config.mrt_ingest_profile
      end

      def mrt_inv_db
        @mrt_inv_db ||= InventoryDB.from_file(config.db_config_path)
      end

      def mrt_ingest_client
        # TODO: secure way to get username and password?
        @mrt_ingest_client ||= Mrt::Ingest::Client.new(mrt_ingest_url)
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

      def process_feed(feed, server)
        last_harvest_next = LastHarvest.new(
          oldest_failed: last_harvest.oldest_failed,
          newest_success: last_harvest.newest_success
        )
        feed.each { |r| process_record(r, server, last_harvest_next) }

        log.debug("Updating #{config.last_harvest_path}:\n#{last_harvest_next.to_yaml.gsub(/^/, "\t")}")
        update_last_harvest!(last_harvest_next)
      end

      def update_last_harvest!(last_harvest_next)
        if dry_run?
          log.info("Dry run: #{config.last_harvest_path} not updated")
        else
          last_harvest_next.write_to(config.last_harvest_path)
        end
      end

      def process_record(r, server, last_harvest_next)
        RecordProcessor.new(r, self, server).process_record!
        last_harvest_next.update(success: r)
      rescue StandardError => e
        log.warn(e)
        last_harvest_next.update(failure: r)
      end

      def query_uri(opts)
        query = '?ListRecords'
        opts.each { |k, v| query << "&#{k}=#{v}" } if opts
        oai_base_uri.merge(query)
      end

      def to_oai_opts(from_time, until_time)
        from_iso8601, until_iso8601 = Times.iso8601_range(from_time, until_time)
        { from: from_iso8601, until: until_iso8601, set: config.oai_set }.compact
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
