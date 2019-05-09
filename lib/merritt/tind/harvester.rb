require 'faraday_middleware'
require 'oai/client'
require 'yaml'

module Merritt
  module TIND
    class Harvester

      attr_reader :base_url
      attr_reader :set

      def initialize(base_url, set)
        @base_url = base_url
        @set = set
        @client = oai_client_for(base_url)
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

      class << self
        def config_env
          %w(HARVESTER_ENV RAILS_ENV RACK_ENV).each { |v| return ENV[v] if ENV[v] }
          'development'
        end

        def from_config(config_yml)
          config = File.exist?(config_yml) ? YAML.load_file(config_yml) : YAML.load(config_yml)
          env_config = config[config_env]
          Harvester.new(env_config['base_url'], env_config['set'])
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
      end

    end
  end
end
