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

  end
end
