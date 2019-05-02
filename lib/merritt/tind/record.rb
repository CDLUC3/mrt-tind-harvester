require 'oai/client'
require 'time'

module Merritt
  module TIND
    class Record
      attr_reader :identifier, :datestamp

      # Constructs a new {Record} wrapping the specified record.
      #
      # @param oai_record [OAI::Record] An OAI record as returned by `OAI::Client`
      def initialize(oai_record)
        raise ArgumentError, "can't parse nil record" unless oai_record

        @identifier, @datestamp = extract_headers(oai_record.header)
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
