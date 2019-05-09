require 'logger'
require 'time'

module Merritt
  module TIND
    module Logging
      NUM_LOG_FILES = 10
      DEFAULT_LOG_LEVEL = Logger::DEBUG

      class << self
        def fmt_log(severity, datetime, _, msg)
          "#{datetime.iso8601}\t#{severity}\t#{msg}\n"
        end

        def new_logger(log_dev = nil, log_level = nil)
          log_dev ||= STDERR
          log_level ||= Logger::DEBUG
          Logger.new(log_dev, NUM_LOG_FILES, level: log_level, formatter: Logging.method(:fmt_log))
        end
      end
    end
  end
end
