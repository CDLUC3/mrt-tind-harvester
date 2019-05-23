require 'time'

module Merritt
  module TIND
    module Times
      class << self
        def iso8601_range(from_time, until_time)
          from_time, until_time = valid_range(from_time, until_time)
          [
            from_time && from_time.iso8601,
            until_time && until_time.iso8601
          ]
        end

        private

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
end
