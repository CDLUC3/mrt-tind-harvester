require 'spec_helper'
require 'logger'

module Merritt
  module TIND
    describe Config do

      describe :from_file do
        it 'constructs a valid config' do
          logdev = instance_double(Logger::LogDevice)
          allow(logdev).to receive(:write)
          expect(Logger::LogDevice).to receive(:new)
            .with(
              'tind-harvester-test.log',
              hash_including(shift_age: Logging::NUM_LOG_FILES)
            )
            .and_return(logdev)

          config = Config.from_file('spec/data/tind-harvester-config.yml')
          harvester = config.new_harvester
          expect(harvester.base_url).to eq('https://tind.example.edu/oai2d')
          expect(harvester.set).to eq('calher130')
          log = harvester.log
          expect(log.level).to eq(Logger::INFO)

          msg = 'help I am trapped in a logging factory'
          expect(logdev).to receive(:write).with(match(/[0-9T:+-]+\tWARN\t#{msg}/))
          log.warn(msg)
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
end
