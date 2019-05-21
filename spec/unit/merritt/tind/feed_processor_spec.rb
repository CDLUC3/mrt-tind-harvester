require 'spec_helper'

module Merritt::TIND
  describe FeedProcessor do
    attr_reader :feed
    attr_reader :harvester
    attr_reader :server

    attr_reader :records

    attr_reader :log
    attr_reader :config
    attr_reader :inv_db

    attr_reader :feed_processor

    attr_reader :tmpdir
    attr_reader :last_harvest_path

    before(:each) do
      @feed = instance_double(Feed)
      @harvester = instance_double(Harvester)
      allow(harvester).to receive(:last_harvest).and_return(nil)
      allow(harvester).to receive(:mrt_collection_ark).and_return(ArkHelper.next_ark)

      @server = instance_double(Mrt::Ingest::OneTimeServer)
      @feed_processor = FeedProcessor.new(feed: feed, server: server, harvester: harvester)

      @config = instance_double(Config)
      allow(harvester).to receive(:config).and_return(config)

      @tmpdir = Dir.mktmpdir
      @last_harvest_path = Pathname.new(tmpdir) + 'last-harvest.yml'
      allow(config).to receive(:last_harvest_path).and_return(last_harvest_path)

      @log = instance_double(Logger)
      allow(harvester).to receive(:log).and_return(log)
      allow(log).to receive(:info)
      allow(log).to receive(:debug)

      @inv_db = instance_double(InventoryDB)
      allow(harvester).to receive(:mrt_inv_db).and_return(inv_db)
      allow(inv_db).to receive(:find_existing_object).and_return(nil)
    end

    after(:each) do
      FileUtils.remove_entry(tmpdir)
    end

    describe :process_feed! do

      attr_reader :processors

      before(:each) do
        start = Time.at(Time.now.to_i) # round to seconds
        @records = Array.new(3) do |i|
          record = instance_double(Record)
          identifier = "r#{i}"
          datestamp = start + i
          allow(record).to receive(:datestamp).and_return(datestamp)
          allow(record).to receive(:local_id).and_return(identifier)
          allow(record).to receive(:content_uri).and_return("http://example.org/file-#{i}.bin")
          allow(record).to receive(:to_h).and_return({
                                                       Record::IDENTIFIER => identifier,
                                                       Record::DATESTAMP => datestamp
                                                     })
          record
        end

        expectation = expect(feed).to receive(:each)
        records.each { |r| expectation = expectation.and_yield(r) }

        @processors = records.map do |r|
          processor = instance_double(RecordProcessor)
          expect(RecordProcessor).to receive(:new).with(r, harvester, server).and_return(processor)
          processor
        end
      end

      describe 'dryrun' do
        before(:each) do
          allow(harvester).to receive(:dry_run?).and_return(true)

          expect(server).not_to receive(:start_server)
          expect(server).not_to receive(:join_server)
          expect_any_instance_of(LastHarvest).not_to receive(:write_to)
        end

        it 'processes the feed' do
          processors.each { |p| expect(p).to receive(:process_record!) }
          feed_processor.process_feed!
        end
      end

      describe 'non-dryrun' do
        before(:each) do
          allow(harvester).to receive(:dry_run?).and_return(false)
        end

        it 'processes the feed' do
          expect(log).not_to receive(:warn)
          processors.each { |p| expect(p).to receive(:process_record!) }
          feed_processor.process_feed!
        end

        it 'updates LastHarvest' do
          expect(log).to receive(:warn).once
          processors.each_with_index do |p, i|
            expectation = expect(p).to receive(:process_record!)
            expectation.and_raise(Mrt::Ingest::IngestException) if i == 0
          end
          feed_processor.process_feed!
          lh = LastHarvest.from_file(last_harvest_path)
          expect(lh.oldest_failed_datestamp).to eq(records.first.datestamp)
          expect(lh.newest_success_datestamp).to eq(records.last.datestamp)
        end
      end

    end
  end
end
