require 'logger'
require 'yaml'
require 'time'

module Merritt
  module TIND
    class Config

      attr_reader :config

      def initialize(config = nil)
        @config = config || {}
      end

      def base_url
        @base_url ||= config['base_url']
      end

      def set
        @set ||= config['set']
      end

      def new_harvester
        logger = Logging.new_logger(config['log_path'], config['log_level'])
        Harvester.new(base_url, set, logger)
      end

      class << self

        def from_file(config_yml)
          config = YAML.load_file(config_yml)
          env_config = config[environment]
          Config.new(env_config)
        end

        def environment
          %w[HARVESTER_ENV RAILS_ENV RACK_ENV].each { |v| return ENV[v] if ENV[v] }
          'development'
        end
      end

    end
  end
end
