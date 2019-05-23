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

    describe :new do
      it 'requires a URL' do
        expect { Harvester.new(Config.new) }.to raise_error(URI::InvalidURIError)
      end

      it 'requires a valid URL' do
        bad_url = 'http://not a hostname/oai2d'
        config = Config.new({ 'base_url' => bad_url })
        expect { Harvester.new(config) }.to raise_error(URI::InvalidURIError)
      end
    end

    describe 'configuration' do
      attr_reader :config
      attr_reader :harvester

      before :each do
        @config = Config.from_file('spec/data/config.yml')
        @harvester = Harvester.new(config)
      end

      it 'reads the collection ARK' do
        expect(harvester.mrt_collection_ark).to eq(config.mrt_collection_ark)
      end

      it 'reads the ingest profile name' do
        expect(harvester.mrt_ingest_profile).to eq(config.mrt_ingest_profile)
      end

      it 'reads the DB config path' do
        inv_db = instance_double(InventoryDB)
        expect(InventoryDB).to receive(:from_file).with(config.db_config_path).and_return(inv_db)
        expect(harvester.mrt_inv_db).to eq(inv_db)
      end

      it 'reads the ingest URL' do
        ingest_client = instance_double(Mrt::Ingest::Client)
        expect(Mrt::Ingest::Client).to receive(:new).with(config.mrt_ingest_url).and_return(ingest_client)
        expect(harvester.mrt_ingest_client).to eq(ingest_client)
      end
    end

    describe(:process_feed!) do
      attr_reader :tmpdir
      attr_reader :last_harvest_path

      attr_reader :base_url
      attr_reader :set
      attr_reader :config

      attr_reader :harvester
      attr_reader :feed
      attr_reader :server
      attr_reader :feed_processor

      before(:each) do
        @tmpdir = Dir.mktmpdir
        @last_harvest_path = Pathname.new(tmpdir) + 'last-harvest.yml'

        @base_url = 'https://tind.example.edu/oai2d'
        @set = 'calher130'
        config_h = {
          'last_harvest' => last_harvest_path.to_s,
          'stop_file' => Pathname.new(tmpdir) + 'stop.txt',
          'oai' => { 'base_url' => base_url, 'set' => set }
        }
        @config = Config.new(config_h)
        @harvester = Harvester.new(config)

        @feed = instance_double(Feed)
        allow(Feed).to receive(:new).with(kind_of(OAI::ListRecordsResponse)).and_return(feed)

        @server = instance_double(Mrt::Ingest::OneTimeServer)
        allow(Mrt::Ingest::OneTimeServer).to receive(:new).and_return(server)

        @feed_processor = instance_double(FeedProcessor)
        allow(FeedProcessor).to receive(:new).with(harvester: harvester, feed: feed, server: server).and_return(feed_processor)
      end

      after(:each) do
        FileUtils.remove_entry(tmpdir)
      end

      it "doesn't harvest or process if stop file is present" do
        expect(config.stop_file_path).not_to be_nil # just to be sure
        FileUtils.touch(config.stop_file_path)

        expect(Feed).not_to receive(:new)
        expect(Mrt::Ingest::OneTimeServer).not_to receive(:new)
        expect(feed_processor).not_to receive(:process_feed!)
        harvester.process_feed!
      end

      it 'harvests but does not process if dry run flag is set' do
        expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}"
        stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

        harvester = Harvester.new(config, dry_run: true)

        expect(Mrt::Ingest::OneTimeServer).not_to receive(:new)

        expect(FeedProcessor).to receive(:new).with(harvester: harvester, feed: feed, server: nil).and_return(feed_processor)
        expect(feed_processor).to receive(:process_feed!)

        harvester.process_feed!
      end

      it 'processes the feed' do
        expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}"
        stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

        expect(server).to receive(:start_server)
        expect(server).to receive(:join_server)
        expect(feed_processor).to receive(:process_feed!)

        harvester.process_feed!
      end

      it 'accepts from and until' do
        expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&from=2015-01-01T01:02:03Z&until=2015-12-31T04:05:06Z"
        stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

        from_time = Time.utc(2015, 1, 1, 1, 2, 3)
        until_time = Time.utc(2015, 12, 31, 4, 5, 6)

        expect(server).to receive(:start_server)
        expect(server).to receive(:join_server)
        expect(feed_processor).to receive(:process_feed!)

        harvester.process_feed!(from_time: from_time, until_time: until_time)
      end

      it 'rejects invalid ranges' do
        expect(Mrt::Ingest::OneTimeServer).not_to receive(:new)
        expect(feed_processor).not_to receive(:process_feed!)

        from_time = Time.now - 1
        until_time = Time.now + 1
        expect { harvester.process_feed!(from_time: until_time, until_time: from_time) }.to raise_error(RangeError)
      end

      it 'rejects non-Times' do
        expect(Mrt::Ingest::OneTimeServer).not_to receive(:new)
        expect(feed_processor).not_to receive(:process_feed!)

        expect { harvester.process_feed!(from_time: Time.now, until_time: Date.today) }.to raise_error(ArgumentError)
        expect { harvester.process_feed!(from_time: Date.today, until_time: Time.now) }.to raise_error(ArgumentError)
        expect { harvester.process_feed!(from_time: Time.now, until_time: Time.now.iso8601) }.to raise_error(ArgumentError)
        expect { harvester.process_feed!(from_time: Time.now.iso8601, until_time: Time.now) }.to raise_error(ArgumentError)
      end

      it 'allows until to be omitted' do
        expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&from=2015-01-01T01:02:03Z"
        stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

        expect(server).to receive(:start_server)
        expect(server).to receive(:join_server)
        expect(feed_processor).to receive(:process_feed!)

        from_time = Time.utc(2015, 1, 1, 1, 2, 3)
        harvester.process_feed!(from_time: from_time)
      end

      it 'allows from to be omitted' do
        expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&until=2015-12-31T04:05:06Z"
        stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

        expect(server).to receive(:start_server)
        expect(server).to receive(:join_server)
        expect(feed_processor).to receive(:process_feed!)

        until_time = Time.utc(2015, 12, 31, 4, 5, 6)
        harvester.process_feed!(until_time: until_time)
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

      it 'creates the log directory if it does not exist' do
        tmpdir = Dir.mktmpdir
        log_file = File.join(tmpdir, 'log', 'test.log')
        expect(Logger::LogDevice).to receive(:new).and_call_original
        begin
          config_h = {
            'log' => { 'file' => log_file },
            'oai' => { 'base_url' => 'https://tind.example.edu/oai2d', 'set' => 'calher130' }
          }
          config = Config.new(config_h)
          harvester = Harvester.new(config)
          log = harvester.log
          msg = 'help I am trapped in a logging factory'
          log.info(msg)
          log_file_data = File.read(log_file)
          expect(log_file_data).to include(msg)
        ensure
          FileUtils.remove_entry(tmpdir)
        end
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
