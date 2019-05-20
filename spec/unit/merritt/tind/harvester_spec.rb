require 'spec_helper'
require 'logger'
require 'pathname'

module Merritt::TIND
  describe Harvester do

    attr_reader :logdev

    before(:each) do
      @logdev = instance_double(Logger::LogDevice)
      allow(logdev).to receive(:write)
      allow(Logger::LogDevice).to receive(:new).and_return(logdev)
    end

    describe 'invalid' do
      it 'requires a URL' do
        expect { Harvester.new(Config.new) }.to raise_error(URI::InvalidURIError)
      end

      it 'requires a valid URL' do
        bad_url = 'http://not a hostname/oai2d'
        config = Config.new({ 'base_url' => bad_url })
        expect { Harvester.new(config) }.to raise_error(URI::InvalidURIError)
      end
    end

    describe 'valid' do
      attr_reader :base_url
      attr_reader :config
      attr_reader :harvester
      attr_reader :set

      before(:each) do
        @base_url = 'https://tind.example.edu/oai2d'
        @set = 'calher130'
        config_h = { 'oai' => { 'base_url' => base_url, 'set' => set } }
        @config = Config.new(config_h)
        @harvester = Harvester.new(config)
      end

      describe(:harvest) do

        # TODO: use proper shared example?
        def verify_feed(feed)
          expected_ids = (5541..5565).map { |i| "oai:berkeley-test.tind.io:#{i}" }
          count = 0
          feed.each_with_index do |r, i|
            expected_id = expected_ids[i]
            expect(r.identifier).to eq(expected_id)
            count += 1
          end
          expect(count).to eq(expected_ids.size)
        end

        it 'harvests the records' do
          expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}"
          stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

          feed = harvester.harvest
          verify_feed(feed)
        end

        describe 'date ranges' do

          it 'accepts from and until' do
            expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&from=2015-01-01T01:02:03Z&until=2015-12-31T04:05:06Z"
            stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

            from_time = Time.utc(2015, 1, 1, 1, 2, 3)
            until_time = Time.utc(2015, 12, 31, 4, 5, 6)

            feed = harvester.harvest(from_time: from_time, until_time: until_time)
            verify_feed(feed)
          end

          it 'accepts explicit nil for from and until' do
            expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}"
            stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

            feed = harvester.harvest(from_time: nil, until_time: nil)
            verify_feed(feed)
          end

          it 'rejects invalid ranges' do
            from_time = Time.utc(2015, 1, 1, 1, 2, 3)
            until_time = Time.utc(2015, 12, 31, 4, 5, 6)
            expect { harvester.harvest(from_time: until_time, until_time: from_time) }.to raise_error(RangeError)
          end

          it 'rejects non-Times' do
            from_time = Time.utc(2015, 1, 1, 1, 2, 3)
            until_time = Time.utc(2015, 12, 31, 4, 5, 6)
            expect { harvester.harvest(from_time: until_time, until_time: Date.today) }.to raise_error(ArgumentError)
            expect { harvester.harvest(from_time: Date.today, until_time: from_time) }.to raise_error(ArgumentError)
            expect { harvester.harvest(from_time: until_time, until_time: until_time.iso8601) }.to raise_error(ArgumentError)
            expect { harvester.harvest(from_time: until_time.iso8601, until_time: from_time) }.to raise_error(ArgumentError)
          end

          describe 'from without until' do
            it 'allows until to be omitted' do
              expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&from=2015-01-01T01:02:03Z"
              stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

              from_time = Time.utc(2015, 1, 1, 1, 2, 3)

              feed = harvester.harvest(from_time: from_time)
              verify_feed(feed)
            end

            it 'allows until to be explicitly nil' do
              expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&from=2015-01-01T01:02:03Z"
              stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

              from_time = Time.utc(2015, 1, 1, 1, 2, 3)

              feed = harvester.harvest(from_time: from_time, until_time: nil)
              verify_feed(feed)
            end
          end

          describe 'until without from' do
            it 'allows from to be omitted' do
              expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&until=2015-12-31T04:05:06Z"
              stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

              until_time = Time.utc(2015, 12, 31, 4, 5, 6)

              feed = harvester.harvest(until_time: until_time)
              verify_feed(feed)
            end

            it 'allows from to be explicitly nil' do
              expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&until=2015-12-31T04:05:06Z"
              stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

              until_time = Time.utc(2015, 12, 31, 4, 5, 6)

              feed = harvester.harvest(from_time: nil, until_time: until_time)
              verify_feed(feed)
            end
          end

        end
      end
    end

    describe :log do
      it 'logs to the configured logger' do
        log_path = Pathname.new('spec/data/tind-harvester-test.log').expand_path
        expect(Logger::LogDevice).to receive(:new)
          .with(log_path, hash_including(shift_age: Logging::NUM_LOG_FILES))
          .and_return(logdev)

        harvester = Harvester.from_file('spec/data/config.yml')
        log = harvester.log
        expect(log.level).to eq(Logger::INFO)

        msg = 'help I am trapped in a logging factory'
        expect(logdev).to receive(:write).with(match(/[0-9TZ:+-]+\tWARN\t#{msg}/))
        log.warn(msg)
      end
    end

    describe :determine_from_time do
      attr_reader :harvester

      before(:each) do
        @harvester = Harvester.from_file('spec/data/config.yml')
      end

      it 'defaults to harvesting all records' do
        allow(LastHarvest).to receive(:from_file).and_return(LastHarvest.new)
        expect(harvester.determine_from_time).to be_nil
      end

      it 'prefers an explicit start time, if set' do
        from_time = Time.now
        expect(harvester.determine_from_time(from_time)).to eq(from_time)
      end

      it 'prefers the "oldest failed" time, if no explicit start time set' do
        lh = harvester.last_harvest
        expect(harvester.determine_from_time).to eq(lh.oldest_failed_datestamp)
      end

      it 'falls back to the "newest success" time, if no explicit start time or "oldest failed" set' do
        newest_success = harvester.last_harvest.newest_success
        allow(LastHarvest).to receive(:from_file).and_return(LastHarvest.new(newest_success: newest_success))
        expect(harvester.determine_from_time).to eq(newest_success.datestamp)
      end
    end

    describe :last_harvest do
      it 'reads a relative path' do
        expected = LastHarvest.from_file('spec/data/last-harvest.yml')
        actual = Harvester.from_file('spec/data/config.yml').last_harvest
        expect(actual).not_to be_nil
        expect(actual.to_h).to eq(expected.to_h)
      end
    end

  end
end
