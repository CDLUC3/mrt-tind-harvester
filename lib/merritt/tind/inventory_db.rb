require 'mysql2'

module Merritt
  module TIND
    class InventoryDB

      attr_reader :db_connection

      def initialize(db_config_h)
        @db_connection = Mysql2::Client.new(db_config_h)
      end

      class << self
        def from_file(db_config_path)
          raise "Can't connect to nil database" unless db_config_path
          raise ArgumentError, "Specified database config #{db_config_path} does not exist" unless File.exist?(db_config_path)

          db_config = YAML.load_file(db_config_path)
          env_db_config = db_config[Config.environment]
          InventoryDB.new(env_db_config)
        end
      end

      def find_existing_object(local_id, collection_ark)
        result = existing_object_stmt.execute(local_id, collection_ark).first
        return nil unless result

        OpenStruct.new(result)
      end

      private

      EXISTING_OBJECT_SQL = <<~SQL.freeze
        SELECT inv_objects.*
          FROM inv_objects
          JOIN inv_collections_inv_objects
            ON inv_collections_inv_objects.inv_object_id = inv_objects.id
          JOIN inv_collections
            ON inv_collections.id = inv_collections_inv_objects.inv_collection_id
          JOIN inv_localids
            ON inv_localids.inv_object_ark = inv_objects.ark
         WHERE inv_localids.local_id = ?
           AND inv_collections.ark = ?
        LIMIT 1
      SQL

      def existing_object_stmt
        @existing_object_stmt ||= db_connection.prepare(EXISTING_OBJECT_SQL)
      end

    end
  end
end
