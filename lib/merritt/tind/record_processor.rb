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

      EXISTING_OBJECT_SQL = <<~SQL.freeze
            SELECT inv_objects.*
              FROM inv_objects
        INNER JOIN inv_collections_inv_objects
                ON inv_collections_inv_objects.inv_object_id = inv_objects.id
        INNER JOIN inv_collections
                ON inv_collections.id = inv_collections_inv_objects.inv_collection_id
             WHERE (erc_where LIKE '%?%')
               AND inv_collections.ark = ?
          ORDER BY inv_objects.id ASC
             LIMIT 1
      SQL

      def log
        config.log
      end

      def db_connection
        config.db_connection
      end

      def find_existing_object
        collection_ark = config.collection_ark
        primary_local_id = local_id
        result = existing_object_stmt.execute(primary_local_id, collection_ark).first
        return nil unless result

        OpenStruct.new(result)
      end

      # TODO: move this to Config (?) so we can re-use it per record
      def existing_object_stmt
        @existing_object_stmt ||= db_connection.prepare(EXISTING_OBJECT_SQL)
      end
    end
  end
end
