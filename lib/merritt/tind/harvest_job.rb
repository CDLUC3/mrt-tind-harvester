module Merritt
  module TIND
    class HarvestJob

      # @return [Config] The configuration
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def process_feed!(from_time: nil, until_time: nil)
        from_time = determine_from_time(from_time)
        feed = harvester.harvest(from_time: from_time, until_time: until_time)
        feed.each do |r|
          record_processor = RecordProcessor.new(record: r, config: config)
          record_processor.process_record!
        end
      end

      private

      def determine_from_time(from_time)
        return from_time if from_time

        oldest_failed = last_harvest.oldest_failed_datestamp
        return oldest_failed if oldest_failed

        last_harvest.newest_success_datestamp
      end

      def harvester
        @harvester ||= config.new_harvester
      end

      def last_harvest
        config.last_harvest
      end

      class << self
        def from_config_file(config_yml)
          config = Config.from_file(config_yml)
          HarvestJob.new(config)
        end
      end
    end
  end
end
