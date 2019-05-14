require 'spec_helper'
require 'tempfile'
require 'time'

module Merritt::TIND
  describe LastHarvest do
    describe :from_file do
      it 'reads the file' do
        lh = LastHarvest.from_file('spec/data/last_tind_harvest.yml')
        of = lh.oldest_failed
        expect(of).not_to(be_nil)
        expect(of.identifier).to eq('oai:berkeley-test.tind.io:5541')
        expect(of.datestamp).to eq(Time.utc(2019, 4, 23, 12, 34, 56))

        ns = lh.newest_success
        expect(ns).not_to(be_nil)
        expect(ns.identifier).to eq('oai:berkeley-test.tind.io:5565')
        expect(ns.datestamp).to eq(Time.utc(2019, 4, 23, 13, 35, 57))
      end
    end

    describe :write_to do
      attr_reader :tmpdir
      attr_reader :last_harvest

      DAY_SECONDS = 86_400

      before :each do
        @tmpdir = Dir.mktmpdir('last_harvest_spec')

        time_now = Time.now
        oldest_failed = Record.new(identifier: 'oldest-failed-record', datestamp: time_now - DAY_SECONDS)
        newest_success = Record.new(identifier: 'newest-success-record', datestamp: time_now)
        @last_harvest = LastHarvest.new(oldest_failed: oldest_failed, newest_success: newest_success)
      end

      after :each do
        FileUtils.remove_entry(tmpdir)
      end

      it 'writes to a file' do
        file = File.join(tmpdir, 'last_tind_harvest.yml')
        last_harvest.write_to(file)
        round_trip = LastHarvest.from_file(file)
        expect(round_trip.to_h).to eq(last_harvest.to_h)
      end

      it 'rotates existing files' do
        expect(Dir.empty?(tmpdir)).to eq(true) # just to be sure

        file = File.join(tmpdir, 'last_tind_harvest.yml')
        last_harvest.write_to(file)

        time_now = Time.now
        oldest_failed = Record.new(identifier: 'oldest-failed-record', datestamp: time_now - DAY_SECONDS)
        newest_success = Record.new(identifier: 'newest-success-record', datestamp: time_now)
        next_harvest = LastHarvest.new(oldest_failed: oldest_failed, newest_success: newest_success)
        next_harvest.write_to(file)

        entries = Dir.entries(tmpdir).select { |f| File.file?(File.join(tmpdir, f)) }
        expect(entries.size).to eq(2)

        # TODO: check content of rotated and latest file
      end
    end
  end
end
