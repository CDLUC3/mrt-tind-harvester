require 'logger'
require 'pathname'
require 'time'
require 'yaml'

module Merritt
  module TIND
    class Config

      attr_reader :config_h
      attr_reader :config_path

      def initialize(config_h = nil, config_yml: nil)
        @config_h = config_h || {}
        @config_path = Pathname.new(config_yml).realpath if config_yml
      end

      def base_url
        @base_url ||= config_h['base_url']
      end

      def set
        @set ||= config_h['set']
      end

      def last_harvest
        @last_harvest ||= LastHarvest.from_file(last_harvest_path)
      end

      def new_harvester
        Harvester.new(base_url, set, log)
      end

      def log
        @log ||= Logging.new_logger(config_h['log_path'], config_h['log_level'])
      end

      private

      def last_harvest_path
        lh = config_h['last_harvest']
        return nil unless lh

        lh_path = Pathname.new(lh)
        return lh_path if lh_path.absolute?
        return lh_path unless config_path

        (config_path.parent + lh_path).realpath
      end

      class << self

        def from_file(config_yml)
          # A missing config.yml is not normal
          raise ArgumentError, "Can't read config from nil file" unless config_yml
          raise ArgumentError, "Specified config file #{config_yml} does not exist" unless File.exist?(config_yml)

          config_h = YAML.load_file(config_yml)
          env_config = config_h[environment]
          Config.new(env_config, config_yml: config_yml)
        end

        def environment
          %w[HARVESTER_ENV RAILS_ENV RACK_ENV].each { |v| return ENV[v] if ENV[v] }
          'development'
        end
      end

    end
  end
end
