require 'db_spec_helper'

module Merritt::TIND
  describe InventoryDB do
    describe :new do
      it 'initializes from a hash' do
        db_config_h = {
          host: 'localhost',
          adapter: 'mysql2',
          database: 'mrt_tind_harvester_test',
          username: 'travis',
          encoding: 'utf8'
        }
        inventory_db = InventoryDB.new(db_config_h)
        expect(inventory_db.db_connection).not_to be_nil
      end

      it 'initializes from a file' do
        inventory_db = InventoryDB.from_file('.config-travis/database.yml')
        expect(inventory_db.db_connection).not_to be_nil
      end
    end

    describe :find_existing_object do
      attr_reader :inventory_db

      before(:each) do
        @inventory_db = InventoryDB.from_file('.config-travis/database.yml')
      end

      it 'finds nothing in an empty database' do
        existing_object = inventory_db.find_existing_object('0000 0001 1690 159X', ArkHelper.next_ark)
        expect(existing_object).to be_nil
      end

      it 'finds an existing object' do
        collection = create(:inv_collection, name: 'Collection 1', mnemonic: 'collection_1')
        obj = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
        collection.inv_objects << obj

        local_ids = Array.new(3) { |i| create(:inv_localid, local_id: "local-id-#{i}", inv_object: obj, inv_owner: obj.inv_owner) }
        local_ids.each do |lid|
          existing_obj = inventory_db.find_existing_object(lid.local_id, collection.ark)
          expect(existing_obj).not_to be_nil
          expect(existing_obj.ark).to eq(obj.ark)
        end
      end
    end

  end
end
