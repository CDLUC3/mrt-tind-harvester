require 'oai/client'
require 'time'

module Merritt
  module TIND
    class Record
      IDENTIFIER = 'identifier'.freeze
      DATESTAMP = 'datestamp'.freeze

      attr_reader :identifier
      attr_reader :datestamp
      attr_reader :metadata

      def initialize(identifier:, datestamp:, oai_metadata: nil)
        @identifier = identifier
        @datestamp = datestamp
        @metadata = oai_metadata
      end

      def erc
        # TODO: something smarter when we know the real requirements
        {
          'where' => identifier,
          'what' => local_id,
          'when' => dc_dates.first || datestamp,
          'when/created' => dc_dates.first || datestamp,
          'when/modified' => datestamp
        }
      end

      def dc_identifiers
        @dc_identifiers ||= REXML::XPath.match(metadata, './/dc:identifier').map(&:text)
      end

      def dc_dates
        @dc_dates ||= begin
          REXML::XPath.match(metadata, './/dc:date')
            .map(&:text)
            .map { |t| Time.parse(t) }
        end
      end

      def dc_titles
        @dc_titles ||= REXML::XPath.match(metadata, './/dc:title').map(&:text)
      end

      def dc_creators
        @dc_creators ||= REXML::XPath.match(metadata, './/dc:creator').map(&:text)
      end

      def content_uri
        @content_uri ||= begin
          # TODO: something smarter when we know the real requirements
          content_url = dc_identifiers.find do |dc_id|
            dc_id.start_with?('http') && dc_id.end_with?('jpg')
          end
          content_url && URI.parse(content_url)
        end
      end

      def local_id
        # TODO: something smarter when we know the real requirements
        dc_identifiers.first || identifier
      end

      def to_h
        { IDENTIFIER => identifier, DATESTAMP => datestamp }
      end

      class << self

        def later(r1, r2)
          return r1 if r2.nil?
          return r2 if r1.nil?
          return r1 if (r1.datestamp <=> r2.datestamp) > 0

          r2
        end

        def earlier(r1, r2)
          return r1 if r2.nil?
          return r2 if r1.nil?
          return r1 if (r1.datestamp <=> r2.datestamp) < 0

          r2
        end

        def from_hash(h)
          return unless h

          Record.new(identifier: h[IDENTIFIER], datestamp: h[DATESTAMP])
        end

        # Constructs a new {Record} wrapping the specified record.
        #
        # @param oai_record [OAI::Record] An OAI record as returned by `OAI::Client`
        def from_oai(oai_record)
          raise ArgumentError, "can't parse nil record" unless oai_record

          header = oai_record.header
          identifier = header.identifier
          datestamp = header.datestamp && Time.parse(header.datestamp)
          Record.new(identifier: identifier, datestamp: datestamp, oai_metadata: oai_record.metadata)
        end

      end
    end
  end
end
