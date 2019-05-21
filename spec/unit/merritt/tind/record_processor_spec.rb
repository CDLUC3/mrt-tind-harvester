require 'spec_helper'
require 'digest'
require 'ostruct'
require 'pathname'

module Merritt::TIND
  describe RecordProcessor do
    attr_reader :harvester
    attr_reader :server
    attr_reader :record
    attr_reader :local_id
    attr_reader :datestamp
    attr_reader :content_uri
    attr_reader :collection_ark
    attr_reader :processor
    attr_reader :inv_db
    attr_reader :log

    before(:each) do
      @record = instance_double(Record)
      @datestamp = Time.now
      allow(record).to receive(:datestamp).and_return(datestamp)
      @local_id = 'the local ID'
      allow(record).to receive(:local_id).and_return(local_id)
      @content_uri = URI.parse('http://example.org/the-content-uri')
      allow(record).to receive(:content_uri).and_return(content_uri)

      @harvester = instance_double(Harvester)
      @collection_ark = ArkHelper.next_ark('collection')
      allow(harvester).to receive(:mrt_collection_ark).and_return(collection_ark)

      @inv_db = instance_double(InventoryDB)
      allow(harvester).to receive(:mrt_inv_db).and_return(inv_db)

      @log = instance_double(Logger)
      allow(harvester).to receive(:log).and_return(log)
      allow(log).to receive(:info)

      @server = instance_double(Mrt::Ingest::OneTimeServer)

      @processor = RecordProcessor.new(record, harvester, server)

    end

    describe :process_record! do
      it 'returns true w/o submitting if record is up to date' do
        newer_datestamp = datestamp + 1
        existing_object = OpenStruct.new(modified: newer_datestamp)
        allow(inv_db).to receive(:find_existing_object).with(local_id, collection_ark).and_return(existing_object)

        expect(harvester).not_to receive(:dry_run?)
        expect(Mrt::Ingest::IObject).not_to receive(:new)
        expect(processor.process_record!).to eq(true)
      end

      it 'returns true w/o submitting for a dry run' do
        older_datestamp = datestamp - 1
        existing_object = OpenStruct.new(modified: older_datestamp)
        allow(inv_db).to receive(:find_existing_object).with(local_id, collection_ark).and_return(existing_object)

        expect(harvester).to receive(:dry_run?).and_return(true)
        expect(Mrt::Ingest::IObject).not_to receive(:new)
        expect(processor.process_record!).to eq(true)
      end

      describe 'submission' do
        attr_reader :tmpdir
        attr_reader :ingest_client
        attr_reader :ingest_profile

        before(:each) do
          @tmpdir = Dir.mktmpdir

          older_datestamp = datestamp - 1
          existing_object = OpenStruct.new(modified: older_datestamp)
          allow(inv_db).to receive(:find_existing_object).with(local_id, collection_ark).and_return(existing_object)

          allow(harvester).to receive(:dry_run?).and_return(false)

          @ingest_client = instance_double(Mrt::Ingest::Client)
          allow(harvester).to receive(:mrt_ingest_client).and_return(ingest_client)
          @ingest_profile = 'the-ingest-profile'
          allow(harvester).to receive(:mrt_ingest_profile).and_return(ingest_profile)
        end

        after(:each) do
          FileUtils.remove_entry(tmpdir)
        end

        it 'submits the object' do
          erc_hash = {
            'where' => local_id,
            'what' => local_id,
            'when' => datestamp,
            'when/created' => datestamp,
            'when/modified' => datestamp
          }
          allow(record).to receive(:erc).and_return(erc_hash)
          expected_erc = "erc:\n#{erc_hash.map { |k, v| "#{k}: #{v}" }.join("\n")}\n"
          expected_erc_digest = Digest::MD5.hexdigest(expected_erc)

          erc_tmp_path = Tempfile.new('tmp', tmpdir).path
          uri_str = "http://#{Socket.gethostname}:12345/#{File.basename(erc_tmp_path)}"
          expect(server).to receive(:add_file).with(no_args) do |&block|
            File.open(erc_tmp_path, 'w+') do |erc_tmp_file|
              block.call(erc_tmp_file)
            end
            [uri_str, erc_tmp_path]
          end

          expect(server).to receive(:start_server)

          response = instance_double(Mrt::Ingest::Response)
          batch_id = 'the-batch-id'
          expect(response).to receive(:batch_id).and_return(batch_id)
          submission_date = Time.now
          expect(response).to receive(:submission_date).and_return(submission_date)

          expect(ingest_client).to receive(:ingest) do |request|
            expect(request.profile).to eq(ingest_profile)

            manifest_file = request.file
            expect(manifest_file).not_to be_nil

            erc_data = File.read(erc_tmp_path)
            expect(erc_data).to eq(expected_erc)

            manifest_data = File.read(manifest_file.path)
            expect(manifest_data).to include(content_uri.to_s)
            expect(manifest_data).to include(expected_erc_digest)

            expect(request.local_identifier).to eq(local_id)
            expect(request.profile).to eq(ingest_profile)

            response
          end

          expect(processor.process_record!).to eq(true)
        end

      end

    end
  end
end
