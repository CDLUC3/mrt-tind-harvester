require 'faraday_middleware'
require 'oai/client'
require 'yaml'
require 'logger'

module Merritt
  module TIND
    class Harvester

      DEFAULT_LOG_LEVEL = Logger::DEBUG
      NUM_LOG_FILES = 10

      attr_reader :base_url
      attr_reader :set
      attr_reader :log

      def initialize(base_url, set, logger = nil)
        @log = logger || Harvester.new_default_logger
        log.info("initializing harvester for base URL <#{base_url}>, set #{set ? "'#{set}'" : '<nil>'}")

        @base_url = base_url
        @set = set
        @client = Harvester.oai_client_for(base_url)
      end

      def harvest(from_time: nil, until_time: nil)
        opts = to_opts(from_time, until_time)
        log.info("harvesting <#{query_url(opts)}>")
        resp = @client.list_records(opts)
        Feed.new(resp)
      end

      private

      def query_url(opts)
        query_url = base_url + '?ListRecords'
        return query_url unless opts && !opts.empty?

        opts.each { |k, v| query_url << "&#{k}=#{v}" }
        query_url
      end

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

      class << self

        def from_config_file(config_yml)
          config = YAML.load_file(config_yml)
          from_config(config)
        end

        def config_env
          %w[HARVESTER_ENV RAILS_ENV RACK_ENV].each { |v| return ENV[v] if ENV[v] }
          'development'
        end

        def new_default_logger
          logger_from_config({})
        end

        def oai_client_for(base_url)
          # Workaround for https://github.com/code4lib/ruby-oai/issues/45
          http_client = Faraday.new(URI.parse(base_url)) do |conn|
            conn.request(:retry, max: 5, retry_statuses: 503)
            conn.response(:follow_redirects, limit: 5)
            conn.adapter(:net_http)
          end
          OAI::Client.new(base_url, http: http_client)
        end

        private

        def from_config(config)
          env_config = config[config_env]
          base_url = env_config['base_url']
          set = env_config['set']
          Harvester.new(base_url, set, logger_from_config(config))
        end

        def logger_from_config(config)
          logdev = (config && config['log_path']) || STDERR
          shift_age = NUM_LOG_FILES # ignored for non-file logdev
          level = (config && config['log_level']) || DEFAULT_LOG_LEVEL
          Logger.new(logdev, shift_age, level: level)
        end

      end
    end
  end
end
