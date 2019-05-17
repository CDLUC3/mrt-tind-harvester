require 'mrt/ingest'
require 'ostruct'

module Merritt
  module TIND
    class RecordProcessor

      USER_AGENT = 'Merritt/TIND Harvester'.freeze

      attr_reader :record
      attr_reader :harvester
      attr_reader :server

      def initialize(record, harvester, server)
        @record = record
        @harvester = harvester
        @server = server
      end

      def process_record!
        return if already_up_to_date?

        log.info("Processing record: #{local_id} (content: #{content_uri}")
        return if harvester.dry_run
      end

      private

      def do_process
        ingest_object.add_component(content_uri)
        ingest_object.start_ingest(ingest_client, ingest_profile, USER_AGENT)
      end

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

      def content_uri
        record.content_uri
      end

      def collection_ark
        harvester.mrt_collection_ark
      end

      def ingest_client
        harvester.mrt_ingest_client
      end

      def ingest_profile
        harvester.mrt_ingest_profile
      end

      def log
        harvester.log
      end

      def ingest_object
        @ingest_object ||= begin
          Mrt::Ingest::IObject.new(
            erc: record.erc,
            server: server,
            local_identifier: record.local_id
          )
        end
      end
    end
  end
end
