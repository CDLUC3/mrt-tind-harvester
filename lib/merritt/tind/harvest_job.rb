module Merritt
  module TIND
    class HarvestJob
      def initialize(config)
        @config = config
      end

      class << self
        def from_config_file(config_yml)
          config = Config.from_file(config_yml)
          HarvestJob.new(config)
        end
      end
    end
  end
end
