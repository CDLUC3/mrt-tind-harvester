require 'logger'
require 'mysql2/client'
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
        config_h['base_url']
      end

      def collection_ark
        config_h['collection_ark']
      end

      def set
        config_h['set']
      end

      def last_harvest
        @last_harvest ||= LastHarvest.from_file(last_harvest_path)
      end

      def new_harvester
        Harvester.new(self)
      end

      def db_connection
        @db_connection ||= begin
          raise "Can't connect to nil database" unless db_config_path
          raise ArgumentError, "Specified database config #{db_config_path} does not exist" unless File.exist?(db_config_path)

          db_config = YAML.load_file(db_config_path)
          env_db_config = db_config[Config.environment]
          Mysql2::Client.new(env_db_config)
        end
      end

      def log
        @log ||= Logging.new_logger(config_h['log_path'], config_h['log_level'])
      end

      private

      def db_config_path
        @db_config_path ||= begin
          db = config_h['database']
          resolve_relative_path(db)
        end
      end

      def last_harvest_path
        @last_harvest_path ||= begin
          lh = config_h['last_harvest']
          resolve_relative_path(lh)
        end
      end

      def resolve_relative_path(filename)
        return nil unless filename

        pathname = Pathname.new(filename)
        return pathname if pathname.absolute?
        return pathname unless config_path

        (config_path.parent + pathname).realpath
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
