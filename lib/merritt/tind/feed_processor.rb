module Merritt
  module TIND
    class FeedProcessor

      attr_reader :feed
      attr_reader :harvester
      attr_reader :server

      def initialize(feed:, server:, harvester:)
        @feed = feed
        @server = server
        @harvester = harvester
      end

      def process_feed!
        feed.each { |r| process_record(r, server) }

        log.debug("Updating #{config.last_harvest_path}:\n#{last_harvest_next.to_yaml.gsub(/^/, "\t")}")
        update_last_harvest!
      end

      private

      def config
        harvester.config
      end

      def log
        harvester.log
      end

      def dry_run?
        harvester.dry_run?
      end

      def last_harvest_next
        @last_harvest_next ||= begin
          last_harvest = harvester.last_harvest
          last_harvest ? last_harvest.clone : LastHarvest.new
        end
      end

      def update_last_harvest!
        if dry_run?
          log.info("Dry run: #{config.last_harvest_path} not updated")
        else
          last_harvest_next.write_to(config.last_harvest_path)
        end
      end

      def process_record(r, server)
        RecordProcessor.new(r, harvester, server).process_record!
        @last_harvest_next = last_harvest_next.update(success: r)
      rescue StandardError => e
        log.warn(e)
        @last_harvest_next = last_harvest_next.update(failure: r)
      end
    end
  end
end
