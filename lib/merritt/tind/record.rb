require 'oai/client'
require 'time'

module Merritt
  module TIND
    class Record
      IDENTIFIER = 'identifier'.freeze
      DATESTAMP = 'datestamp'.freeze

      attr_reader :identifier, :datestamp

      def initialize(identifier:, datestamp:)
        @identifier = identifier
        @datestamp = datestamp
      end

      def to_h
        {
          IDENTIFIER => identifier,
          DATESTAMP => datestamp
        }
      end

      class << self

        def from_hash(h)
          return unless h

          new Record(
            identifier: h[IDENTIFIER],
            datestamp: h[DATESTAMP]
          )
        end

        # Constructs a new {Record} wrapping the specified record.
        #
        # @param oai_record [OAI::Record] An OAI record as returned by `OAI::Client`
        def from_oai_record(oai_record)
          raise ArgumentError, "can't parse nil record" unless oai_record

          identifier, datestamp = extract_headers(oai_record.header)
          new Record(identifier: identifier, datestamp: datestamp)
        end

        private

        def extract_headers(header)
          [
            header.identifier,
            header.datestamp && Time.parse(header.datestamp)
          ]
        end
      end
    end
  end
end
