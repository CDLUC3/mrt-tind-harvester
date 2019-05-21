require 'spec_helper'
require 'pathname'
require 'tempfile'
require 'time'

module Merritt::TIND
  describe LastHarvest do
    describe :from_file do
      it 'reads the file' do
        lh = LastHarvest.from_file('spec/data/last-harvest.yml')
        of = lh.oldest_failed
        expect(of).not_to(be_nil)
        expect(of.identifier).to eq('oai:berkeley-test.tind.io:5541')
        expect(of.datestamp).to eq(Time.utc(2019, 4, 23, 12, 34, 56))

        ns = lh.newest_success
        expect(ns).not_to(be_nil)
        expect(ns.identifier).to eq('oai:berkeley-test.tind.io:5565')
        expect(ns.datestamp).to eq(Time.utc(2019, 4, 23, 13, 35, 57))
      end

      it 'accepts a pathname' do
        filename = 'spec/data/last-harvest.yml'
        from_file = LastHarvest.from_file(filename)
        pathname = Pathname.new(filename)
        from_path = LastHarvest.from_file(pathname)
        expect(from_path.to_h).to eq(from_file.to_h)
      end

      it 'returns empty for a nonexistent file' do
        Dir.mktmpdir('last_harvest_spec') do |d|
          nonexistent_file = File.join(d, 'nonexistent-file.yml')
          expect(File.exist?(nonexistent_file)).to eq(false) # just to be sure
          lh = LastHarvest.from_file(nonexistent_file)
          expect(lh.oldest_failed).to be_nil
          expect(lh.newest_success).to be_nil
        end
      end

      it 'returns empty for a nil file' do
        lh = LastHarvest.from_file(nil)
        expect(lh.oldest_failed).to be_nil
        expect(lh.newest_success).to be_nil
      end
    end

    describe :clone do
      it 'deep clones the object' do
        lh1 = LastHarvest.from_file('spec/data/last-harvest.yml')
        lh2 = lh1.clone
        expect(lh2.to_h).to eq(lh1.to_h)
        expect(lh2).not_to be(lh1)
        expect(lh2.oldest_failed).not_to be(lh1.oldest_failed)
        expect(lh2.newest_success).not_to be(lh1.newest_success)
      end
    end

    describe :dup do
      it 'deep duplicates the object' do
        lh1 = LastHarvest.from_file('spec/data/last-harvest.yml')
        lh2 = lh1.dup
        expect(lh2.to_h).to eq(lh1.to_h)
        expect(lh2).not_to be(lh1)
        expect(lh2.oldest_failed).not_to be(lh1.oldest_failed)
        expect(lh2.newest_success).not_to be(lh1.newest_success)
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
        file = File.join(tmpdir, 'last-harvest.yml')
        last_harvest.write_to(file)
        round_trip = LastHarvest.from_file(file)
        expect(round_trip.to_h).to eq(last_harvest.to_h)
      end

      it 'rotates existing files' do
        expect(Dir.empty?(tmpdir)).to eq(true) # just to be sure

        filename = File.join(tmpdir, 'last-harvest.yml')
        last_harvest.write_to(filename)

        time_now = Time.now
        oldest_failed = Record.new(identifier: 'oldest-failed-record', datestamp: time_now - DAY_SECONDS)
        newest_success = Record.new(identifier: 'newest-success-record', datestamp: time_now)
        next_harvest = LastHarvest.new(oldest_failed: oldest_failed, newest_success: newest_success)
        next_harvest.write_to(filename)

        entries = Dir.entries(tmpdir)
          .map { |f| File.join(tmpdir, f) }
          .select { |f| File.file?(f) }

        expect(entries.size).to eq(2)
        expect(entries).to include(filename)
        entries.delete(filename)

        rotated_file = entries[0]
        expect(LastHarvest.from_file(rotated_file).to_h).to eq(last_harvest.to_h)

        latest_file = filename
        expect(LastHarvest.from_file(latest_file).to_h).to eq(next_harvest.to_h)
      end
    end
  end
end
