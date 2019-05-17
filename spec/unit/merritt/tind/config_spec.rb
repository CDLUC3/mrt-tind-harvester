require 'spec_helper'
require 'pathname'

module Merritt::TIND
  describe Config do
    describe :from_file do
      it 'constructs a valid config' do
        config = Config.from_file('spec/data/tind-harvester-config.yml')
        expect(config.base_url).to eq('https://tind.example.edu/oai2d')
        expect(config.set).to eq('calher130')
        expect(config.collection_ark).to eq('ark:/13030/m5vd6wc7')
      end

      it 'accepts a pathname' do
        filename = 'spec/data/tind-harvester-config.yml'
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
