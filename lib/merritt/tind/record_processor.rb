require 'mrt/ingest'
require 'ostruct'

module Merritt
  module TIND
    class RecordProcessor

      def initialize(record, harvester)
        @record = record
        @harvester = harvester
      end

      def process_record!
        return if already_up_to_date?

        log.info("Ready to submit id: #{local_id}")
      end

      private

      def already_up_to_date?
        @already_up_to_date ||= existing_object && existing_object.modified >= record.datestamp
      end

      def existing_object
        @existing_object = (find_existing_object || false) if @existing_object.nil?
        @existing_object
      end

      def find_existing_object
        inv_db.find_existing_object(local_id, collection_ark)
      end

      def inv_db
        harvester.mrt_inv_db
      end

      def local_id
        record.local_id
      end

      def collection_ark
        harvester.mrt_collection_ark
      end

    end
  end
end
