require 'spec_helper'
require 'rexml/document'

module Merritt::TIND
  describe Record do
    describe :from_oai do
      describe 'invalid' do
        it 'rejects a nil record' do
          expect { Record.from_oai(nil) }.to raise_error(ArgumentError)
        end

        it 'rejects a non-nil record with a nil header' do
          oai_record = instance_double(OAI::Record)
          allow(oai_record).to receive(:header).and_return(nil)
          expect { Record.from_oai(oai_record).to raise_error(ArgumentError) }
        end
      end

      describe 'valid' do
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
      end
    end
  end
end
