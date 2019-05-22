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

          created_log_dir = ensure_log_dir(log_dev)
          logger = Logger.new(log_dev, NUM_LOG_FILES, level: log_level, formatter: Logging.method(:fmt_log))
          created_log_dir.each { |d| logger.info("Created log directory #{d}") } if created_log_dir
          logger
        end

        private

        def io_like?(log_dev)
          # This is how Ruby's Logger identifies an IO-like log device
          log_dev.respond_to?(:write) && log_dev.respond_to?(:close)
        end

        def ensure_log_dir(log_dev)
          return if io_like?(log_dev)

          # assume it's a string or a pathname
          log_dir = Pathname.new(log_dev).parent
          FileUtils.mkdir_p(log_dir) unless log_dir.exist?
        end
      end
    end
  end
end
