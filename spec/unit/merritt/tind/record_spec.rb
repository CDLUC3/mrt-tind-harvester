require 'spec_helper'
require 'rexml/document'

module Merritt::TIND
  describe Record do
    describe :from_oai_record do
      describe 'invalid' do
        it 'rejects a nil record' do
          expect { Record.from_oai_record(nil) }.to raise_error(ArgumentError)
        end

        it 'rejects a non-nil record with a nil header' do
          oai_record = instance_double(OAI::Record)
          allow(oai_record).to receive(:header).and_return(nil)
          expect { Record.from_oai_record(oai_record).to raise_error(ArgumentError) }
        end
      end

      describe 'valid' do
        attr_reader :record

        before(:each) do
          file = File.new('spec/data/record.xml')
          doc = REXML::Document.new(file)
          oai_record = OAI::Record.from_oai_record(doc.root_node)
          @record = Record.from_oai_record(oai_record)
        end

        it 'extracts the identifier' do
          expect(record.identifier).to eq('oai:berkeley-test.tind.io:5542')
        end

        it 'extracts the datestamp' do
          expected = Time.utc(2019, 4, 23, 13, 45, 23)
          expect(record.datestamp).to eq(expected)
        end
      end
    end
  end
end
