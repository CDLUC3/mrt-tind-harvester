require 'spec_helper'

module Merritt::TIND
  describe HarvestJob do
    describe :from_config_file do
      it 'creates a harvest job' do
        job = HarvestJob.from_config_file('spec/data/tind-harvester-config.yml')
        expect(job).not_to(be_nil)
      end
    end

    describe :process_feed! do
      attr_reader :logdev
      attr_reader :job
      attr_reader :harvester
      attr_reader :feed

      before(:each) do
        @logdev = instance_double(Logger::LogDevice)
        allow(logdev).to receive(:write)
        allow(Logger::LogDevice).to receive(:new)
          .with('tind-harvester-test.log', hash_including(shift_age: Logging::NUM_LOG_FILES))
          .and_return(logdev)

        @job = HarvestJob.from_config_file('spec/data/tind-harvester-config.yml')

        config = job.config
        @harvester = instance_double(Harvester)
        allow(Harvester).to receive(:new).with(config).and_return(harvester)

        @feed = instance_double(Feed)
        allow(feed).to receive(:each)
      end

      it 'defaults to harvesting all records' do
        config = job.config
        config.instance_variable_set(:@last_harvest, LastHarvest.new)
        expect(harvester).to receive(:harvest).with(from_time: nil, until_time: nil).and_return(feed)
        job.process_feed!
      end

      it 'prefers an explicit start time, if set' do
        from_time = Time.now
        expect(harvester).to receive(:harvest).with(from_time: from_time, until_time: nil).and_return(feed)
        job.process_feed!(from_time: from_time)
      end

      it 'accepts an explicit end time' do
        until_time = Time.now
        expect(harvester).to receive(:harvest).with(hash_including(until_time: until_time)).and_return(feed)
        job.process_feed!(until_time: until_time)
      end

      it 'prefers the "oldest failed" time, if no explicit start time set' do
        lh = job.config.last_harvest
        expect(harvester).to receive(:harvest).with(hash_including(from_time: lh.oldest_failed_datestamp)).and_return(feed)
        job.process_feed!
      end

      it 'falls back to the "newest success" time, if no explicit start time or "oldest failed" set' do
        lh = job.config.last_harvest
        lh.instance_variable_set(:@oldest_failed, nil)
        expect(harvester).to receive(:harvest).with(hash_including(from_time: lh.newest_success_datestamp)).and_return(feed)
        job.process_feed!
      end
    end
  end
end
