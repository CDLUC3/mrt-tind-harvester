require 'spec_helper'
require 'rexml/document'
require 'webmock/rspec'

module Merritt::TIND
  describe Feed do
    describe :new do
      describe 'valid' do
        attr_reader :feed

        before(:each) do
          file = File.new('spec/data/feed.xml')
          doc = REXML::Document.new(file)
          resp = OAI::ListRecordsResponse.new(doc)
          @feed = Feed.new(resp)
        end

        describe :each do
          it 'yields the records' do
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

    describe 'pagination' do
      before(:each) do
        WebMock.disable_net_connect!
        # 'I am a resumption token' -> UTF-8 bytes -> big integer (little-endian) -> base36
        token = '3kt58j5stglp50mv6wlrbgf7xyl6e2prrebt'
        url1 = 'https://tind.example.edu/oai2d?verb=ListRecords&metadataPrefix=oai_dc&set=calher130'
        stub_request(:get, url1).to_return(status: 200, body: File.new('spec/data/feed-1.xml'))
        url2 = "https://tind.example.edu/oai2d?resumptionToken=#{token}&verb=ListRecords"
        stub_request(:get, url2).to_return(status: 200, body: File.new('spec/data/feed-2.xml'))
      end

      after(:each) do
        WebMock.allow_net_connect!
      end

      it 'handles resumption tokens' do
        client = OAI::Client.new('https://tind.example.edu/oai2d')
        resp = client.list_records(set: 'calher130')
        feed = Feed.new(resp)
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
