require 'spec_helper'
require 'rexml/document'

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
  end
end
