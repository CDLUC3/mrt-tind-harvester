require 'spec_helper'

module Merritt::TIND
  describe Harvester do
    describe 'invalid' do
      it 'requires a URL' do
        expect { Harvester.new(nil, nil) }.to raise_error(URI::InvalidURIError)
      end

      it 'requires a valid URL' do
        bad_url = 'http://not a hostname/oai2d'
        expect { Harvester.new(bad_url, nil) }.to raise_error(URI::InvalidURIError)
      end
    end

    describe 'valid' do
      attr_reader :base_url
      attr_reader :harvester
      attr_reader :set

      before(:each) do
        @base_url = 'https://tind.example.edu/oai2d'
        @set = 'calher130'
        @harvester = Harvester.new(base_url, set)
      end

      describe(:harvest) do
        it 'harvests the records' do
          expected_url = "#{base_url}?verb=ListRecords&metadataPrefix=oai_dc&set=#{set}&from=2015-01-01T01:02:03Z&until=2015-12-31T04:05:06Z"
          stub_request(:get, expected_url).to_return(status: 200, body: File.new('spec/data/feed.xml'))

          from_time = Time.utc(2015, 1, 1, 1, 2, 3)
          until_time = Time.utc(2015, 12, 31, 4, 5, 6)

          feed = harvester.harvest(from_time: from_time, until_time: until_time)
          expected_ids = (5541..5565).map { |i| "oai:berkeley-test.tind.io:#{i}" }
          count = 0
          feed.each_with_index do |r, i|
            expected_id = expected_ids[i]
            expect(r.identifier).to eq(expected_id)
            count += 1
          end
          expect(count).to eq(expected_ids.size)
        end
      end
    end
  end
end
