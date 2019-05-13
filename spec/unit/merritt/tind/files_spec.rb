require 'spec_helper'

module Merritt::TIND
  describe Files do
    attr_reader :tmpdir

    before(:each) do
      @tmpdir = Dir.mktmpdir('files_spec')
    end

    after(:each) do
      FileUtils.remove_dir(tmpdir, true) if tmpdir
    end

    describe :with_lock do
      it 'creates a file' do
        msg = 'help I am trapped in a file lock factory'
        filename = File.join(tmpdir, 'file.bin')

        Files.with_lock(filename) { |f| f.puts(msg) }
        expected_content = msg + "\n"
        actual_content = File.read(filename)
        expect(actual_content).to eq(expected_content)
      end

      it 'appends to an existing file' do
        msg = 'help I am trapped in a file lock factory'
        filename = File.join(tmpdir, 'file.bin')
        File.open(filename, 'w') { |f| f.puts(msg) }

        Files.with_lock(filename) { |f| f.puts(msg) }
        expected_content = "#{msg}\n#{msg}\n"
        actual_content = File.read(filename)
        expect(actual_content).to eq(expected_content)
      end

    end

  end
end
