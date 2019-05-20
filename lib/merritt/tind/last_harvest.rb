require 'yaml'

module Merritt
  module TIND

    class LastHarvest

      OLDEST_FAILED = 'oldest_failed'.freeze
      NEWEST_SUCCESS = 'newest_success'.freeze

      attr_accessor :oldest_failed
      attr_accessor :newest_success

      # @param oldest_failed [Record, nil] the oldest record that failed to submit
      # @param newest_success [Record, nil] the newest record successfully submitted
      def initialize(oldest_failed: nil, newest_success: nil)
        @oldest_failed = oldest_failed
        @newest_success = newest_success
      end

      def to_h
        {
          OLDEST_FAILED => (oldest_failed && oldest_failed.to_h),
          NEWEST_SUCCESS => (newest_success && newest_success.to_h)
        }
      end

      def write_to(last_harvest_yml)
        Files.rotate_and_lock(last_harvest_yml) do |f|
          f.write(to_h.to_yaml)
        end
      end

      def oldest_failed_datestamp
        oldest_failed && oldest_failed.datestamp
      end

      def newest_success_datestamp
        newest_success && newest_success.datestamp
      end

      class << self
        def from_file(last_harvest_yml)
          return from_hash(YAML.load_file(last_harvest_yml)) if last_harvest_yml && File.exist?(last_harvest_yml)

          # A missing last_yarvest.yml is normal
          LastHarvest.new
        end

        def from_hash(h)
          LastHarvest.new(
            oldest_failed: Record.from_hash(h[OLDEST_FAILED]),
            newest_success: Record.from_hash(h[NEWEST_SUCCESS])
          )
        end

      end
    end
  end
end
