require 'spec_helper'
require 'rexml/document'

module Merritt::TIND
  describe Record do
    describe :from_oai do
      describe :new do
        it 'rejects a nil record' do
          expect { Record.from_oai(nil) }.to raise_error(ArgumentError)
        end

        it 'rejects a non-nil record with a nil header' do
          oai_record = instance_double(OAI::Record)
          allow(oai_record).to receive(:header).and_return(nil)
          expect { Record.from_oai(oai_record).to raise_error(ArgumentError) }
        end
      end

      attr_reader :record

      before(:each) do
        file = File.new('spec/data/record.xml')
        doc = REXML::Document.new(file)
        oai_record = OAI::Record.new(doc.root_node)
        @record = Record.from_oai(oai_record)
      end

      it 'extracts the identifier' do
        expect(record.identifier).to eq('oai:berkeley-test.tind.io:5542')
      end

      it 'extracts the datestamp' do
        expected = Time.utc(2019, 4, 23, 13, 45, 23)
        expect(record.datestamp).to eq(expected)
      end

      it 'extracts Dublin Core IDs' do
        expected = [
          'BANC PIC 19xx.069:02--ffALB',
          'http://www.oac.cdlib.org/findaid/ark:/13030/tf1z09n955',
          'http://berkeley-test.tind.io/record/5542/files/I0025874A.jpg',
          'http://berkeley-test.tind.io/record/5542'
        ]
        actual = record.dc_identifiers
        expect(actual.size).to eq(expected.size)
        actual.each_with_index do |actual_id, i|
          expect(actual_id).to eq(expected[i])
        end
      end

      it 'extracts Dublin Core dates' do
        expected = Time.utc(2019, 4, 12, 20, 28, 4)
        actual = record.dc_dates
        expect(actual.size).to eq(1)
        expect(actual[0]).to eq(expected)
      end

      it 'extracts titles' do
        titles = record.dc_titles
        expect(titles).not_to be_nil
        expect(titles.size).to eq(1)
        expect(titles[0]).to eq('Municipal Boat-house on Lake Merritt')
      end

      it 'extracts creators' do
        creators = record.dc_creators
        expect(creators).not_to be_nil
        expect(creators.size).to eq(0) # none currently in test data
      end

      it 'extracts the content URI' do
        # TODO: something smarter when we know the real requirements
        expect(record.content_uri).to eq(URI.parse('http://berkeley-test.tind.io/record/5542/files/I0025874A.jpg'))
      end

      it 'extracts the local ID' do
        # TODO: something smarter when we know the real requirements
        expect(record.local_id).to eq(record.identifier)
      end

      it 'builds an ERC hash' do
        # TODO: something smarter when we know the real requirements
        erc_hash = {
          'where' => record.identifier,
          'what' => record.identifier,
          'when' => record.dc_dates.first,
          'when/created' => record.dc_dates.first,
          'when/modified' => record.datestamp
        }
        expect(record.erc).to eq(erc_hash)
      end
    end
  end

  describe 'comparisons' do
    attr_reader :r1, :r2

    before(:each) do
      @r1 = Record.new(identifier: nil, datestamp: Time.now)
      @r2 = Record.new(identifier: nil, datestamp: Time.now + 1)
    end

    describe :later do
      it 'returns the record with a later timestamp' do
        expect(Record.later(r1, r2)).to eq(r2)
        expect(Record.later(r2, r1)).to eq(r2)
      end
      it 'returns nil if both records are nil' do
        expect(Record.later(nil, nil)).to be_nil
      end
      it 'returns the non-nil record if one record is nil' do
        expect(Record.later(r1, nil)).to eq(r1)
        expect(Record.later(nil, r1)).to eq(r1)
        expect(Record.later(r2, nil)).to eq(r2)
        expect(Record.later(nil, r2)).to eq(r2)
      end
    end

    describe :earlier do
      it 'returns the record with a earlier timestamp' do
        expect(Record.earlier(r1, r2)).to eq(r1)
        expect(Record.earlier(r2, r1)).to eq(r1)
      end
      it 'returns nil if both records are nil' do
        expect(Record.earlier(nil, nil)).to be_nil
      end
      it 'returns the non-nil record if one record is nil' do
        expect(Record.earlier(r2, nil)).to eq(r2)
        expect(Record.earlier(nil, r2)).to eq(r2)
        expect(Record.earlier(r1, nil)).to eq(r1)
        expect(Record.earlier(nil, r1)).to eq(r1)
      end
    end

  end
end
