require 'mrt/ingest'
require 'ostruct'

module Merritt
  module TIND
    class RecordProcessor

      attr_reader :record
      attr_reader :config

      def initialize(record:, config:)
        @record = record
        @config = config
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

      def log
        config.log
      end

      def db_connection
        config.db_connection
      end

      def find_existing_object
        config.find_existing_object(local_id)
      end

    end
  end
end
