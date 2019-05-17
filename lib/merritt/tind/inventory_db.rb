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
        SELECT o.*
          FROM inv_objects AS o
               JOIN inv_collections_inv_objects AS co
                 ON co.inv_object_id = o.id
               JOIN inv_collections AS c
                 ON c.id = co.inv_collection_id
               JOIN inv_localids AS li
                 ON li.inv_object_ark = o.ark
         WHERE li.local_id = ?
           AND c.ark = ?
        LIMIT 1
      SQL

      def existing_object_stmt
        @existing_object_stmt ||= db_connection.prepare(EXISTING_OBJECT_SQL)
      end

    end
  end
end
