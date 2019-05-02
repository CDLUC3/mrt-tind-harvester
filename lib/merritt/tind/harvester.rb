require 'oai/client'

module Merritt
  module TIND
    class Harvester

      def initialize(base_url, set)
        @client = OAI::Client.new(base_url)
        @set = set
      end

      def harvest(from_time: nil, until_time: nil)
        opts = to_opts(from_time, until_time)
        resp = @client.list_records(opts)
        Feed.new(resp)
      end

      private

      def to_opts(from_time, until_time)
        from_time, until_time = valid_range(from_time, until_time)
        {
          from: from_time && from_time.iso8601,
          until: until_time && until_time.iso8601,
          set: @set
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

    end
  end
end
