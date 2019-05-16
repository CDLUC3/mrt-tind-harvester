require 'oai/client'
require 'time'

module Merritt
  module TIND
    class Record
      IDENTIFIER = 'identifier'.freeze
      DATESTAMP = 'datestamp'.freeze
      DC_IDENTIFIERS = 'dc_identifiers'.freeze

      attr_reader :identifier, :datestamp, :dc_identifiers

      def initialize(identifier:, datestamp:, dc_identifiers:)
        @identifier = identifier
        @datestamp = datestamp
        @dc_identifiers = dc_identifiers
      end

      # TODO: something smarter when we know the real requirements
      # :nocov:
      def content_url
        dc_identifiers.find do |dc_id|
          dc_id.start_with?('http') && dc_id.end_with?('jpg')
        end
      end
      # :nocov:

      def to_h
        { IDENTIFIER => identifier, DATESTAMP => datestamp, DC_IDENTIFIERS => dc_identifiers }
      end

      class << self

        def from_hash(h)
          return unless h

          Record.new(
            identifier: h[IDENTIFIER],
            datestamp: h[DATESTAMP],
            dc_identifiers: h[DC_IDENTIFIERS]
          )
        end

        # Constructs a new {Record} wrapping the specified record.
        #
        # @param oai_record [OAI::Record] An OAI record as returned by `OAI::Client`
        def from_oai(oai_record)
          raise ArgumentError, "can't parse nil record" unless oai_record

          # TODO: parse 'real' identifier out of Dublin Core?
          identifier, datestamp = extract_headers(oai_record.header)
          dc_id = extract_dc_ids(oai_record.metadata)
          Record.new(identifier: identifier, datestamp: datestamp, dc_identifiers: dc_id)
        end

        private

        def extract_dc_ids(metadata)
          REXML::XPath.match(metadata, './/dc:identifier').map(&:text)
        end

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
