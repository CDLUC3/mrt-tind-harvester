require 'spec_helper'
require 'pathname'
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

      it 'accepts a pathname' do
        filename = 'spec/data/last_tind_harvest.yml'
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

    describe :write_to do
      attr_reader :tmpdir
      attr_reader :last_harvest
      attr_reader :failed_ids
      attr_reader :success_ids

      DAY_SECONDS = 86_400

      before :each do
        @tmpdir = Dir.mktmpdir('last_harvest_spec')

        @failed_ids =  [
          'BANC PIC 19xx.069:02--ffALB',
          'http://www.oac.cdlib.org/findaid/ark:/13030/tf1z09n955',
          'http://berkeley-test.tind.io/record/5542/files/I0025874A.jpg',
          'http://berkeley-test.tind.io/record/5542'
        ]

        @success_ids =  [
          'BANC PIC 19xx.069:25--ffALB',
          'http://www.oac.cdlib.org/findaid/ark:/13030/tf1z09n955',
          'http://berkeley-test.tind.io/record/5565/files/I0025897A.jpg',
          'http://berkeley-test.tind.io/record/5565'
        ]

        time_now = Time.now
        oldest_failed = Record.new(identifier: 'oldest-failed-record', datestamp: time_now - DAY_SECONDS, dc_identifiers: failed_ids)
        newest_success = Record.new(identifier: 'newest-success-record', datestamp: time_now, dc_identifiers: success_ids)
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

        filename = File.join(tmpdir, 'last_tind_harvest.yml')
        last_harvest.write_to(filename)

        time_now = Time.now
        oldest_failed = Record.new(identifier: 'oldest-failed-record', datestamp: time_now - DAY_SECONDS, dc_identifiers: failed_ids)
        newest_success = Record.new(identifier: 'newest-success-record', datestamp: time_now, dc_identifiers: success_ids)
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
