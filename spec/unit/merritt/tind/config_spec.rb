require 'spec_helper'
require 'pathname'

module Merritt::TIND
  describe Config do
    describe :from_file do
      it 'constructs a valid config' do
        config = Config.from_file('spec/data/config.yml')
        expect(config.last_harvest_path).to eq(Pathname.new('spec/data/last-harvest.yml').expand_path)
        expect(config.stop_file_path).to eq(Pathname.new('spec/data/stop.txt').expand_path)

        expect(config.oai_base_url).to eq('https://tind.example.edu/oai2d')
        expect(config.oai_set).to eq('calher130')

        expect(config.mrt_collection_ark).to eq('ark:/13030/m5vd6wc7')
        expect(config.db_config_path).to eq(Pathname.new('spec/data/database.yml').expand_path)
        expect(config.mrt_ingest_url).to eq('http://merritt.example.edu/object/ingest')
        expect(config.mrt_ingest_profile).to eq('ucb_lib_bancroft_content')
        expect(config.log_path).to eq(Pathname.new('spec/data/tind-harvester.log').expand_path)
        expect(config.log_level).to eq('info')
      end

      it 'accepts a pathname' do
        filename = 'spec/data/config.yml'
        from_file = Config.from_file(filename)
        pathname = Pathname.new(filename)
        from_path = Config.from_file(pathname)
        expect(from_path.config_h).to eq(from_file.config_h)
      end
    end

    describe :environment do
      it 'defaults to test in test' do
        expect(Config.environment).to eq('test')
      end

      describe 'from environment' do
        before(:each) do
          @harvester_env_orig = ENV['HARVESTER_ENV']
          @rails_env_orig = ENV['RAILS_ENV']
          @rack_env_orig = ENV['RACK_ENV']
          %w[HARVESTER_ENV RAILS_ENV RACK_ENV].each { |v| ENV[v] = nil }
        end

        after(:each) do
          ENV['HARVESTER_ENV'] = @harvester_env_orig
          ENV['RAILS_ENV'] = @rails_env_orig
          ENV['RACK_ENV'] = @rack_env_orig
        end

        it 'reads from HARVESTER_ENV' do
          expected = 'expected'
          ENV['HARVESTER_ENV'] = expected
          expect(Config.environment).to eq(expected)
        end

        it 'reads from RAILS_ENV' do
          expected = 'expected'
          ENV['RAILS_ENV'] = expected
          expect(Config.environment).to eq(expected)
        end

        it 'reads from RACK_ENV' do
          expected = 'expected'
          ENV['RACK_ENV'] = expected
          expect(Config.environment).to eq(expected)
        end

        it 'prefers HARVESTER_ENV, then RAILS_ENV' do
          %w[HARVESTER_ENV RAILS_ENV RACK_ENV].each { |v| ENV[v] = "value from #{v}" }
          expect(Config.environment).to eq('value from HARVESTER_ENV')
          ENV['HARVESTER_ENV'] = nil
          expect(Config.environment).to eq('value from RAILS_ENV')
          ENV['RAILS_ENV'] = nil
          expect(Config.environment).to eq('value from RACK_ENV')
        end

        it 'defaults to development if not set' do
          %w[HARVESTER_ENV RAILS_ENV RACK_ENV].each { |v| ENV[v] = nil }
          expect(Config.environment).to eq('development')
        end
      end
    end
  end
end
