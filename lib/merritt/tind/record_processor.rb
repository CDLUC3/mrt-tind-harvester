require 'mrt/ingest'
require 'ostruct'

module Merritt
  module TIND
    class RecordProcessor

      attr_reader :record
      attr_reader :inv_db
      attr_reader :log

      def initialize(record:, inv_db:, log:)
        @record = record
        @inv_db = inv_db
        @log = log
      end

      def process_record!
        return if already_up_to_date?

        log.info("Ready to submit id: #{local_id}")
      end

      def already_up_to_date?
        @already_up_to_date ||= existing_object && existing_object.modified >= record.datestamp
      end

      def existing_object
        @existing_object = (find_existing_object || false) if @existing_object.nil?
        @existing_object
      end

      def local_id
        record.local_id
      end

      private

      def find_existing_object
        inv_db.find_existing_object(local_id)
      end

    end
  end
end
