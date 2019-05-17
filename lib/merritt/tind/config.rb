require 'pathname'
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

      def oai_base_url
        oai_config_h['base_url']
      end

      def oai_set
        oai_config_h['set']
      end

      def mrt_collection_ark
        merritt_config_h['collection_ark']
      end

      def mrt_ingest_url
        merritt_config_h['ingest_url']
      end

      def mrt_ingest_profile
        merritt_config_h['ingest_profile']
      end

      def db_config_path
        @db_config_path ||= begin
          db = merritt_config_h['database']
          resolve_relative_path(db)
        end
      end

      def log_level
        log_config_h['level']
      end

      def log_path
        @log_path ||= begin
          lp = log_config_h['file']
          resolve_relative_path(lp)
        end
      end

      def last_harvest_path
        @last_harvest_path ||= begin
          lh = config_h['last_harvest']
          resolve_relative_path(lh)
        end
      end

      private

      def oai_config_h
        config_h['oai'] || {}
      end

      def merritt_config_h
        config_h['merritt'] || {}
      end

      def log_config_h
        config_h['log'] || {}
      end

      def resolve_relative_path(filename)
        return nil unless filename

        pathname = Pathname.new(filename)
        return pathname if pathname.absolute?
        return pathname unless config_path

        (config_path.parent + pathname).cleanpath
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
