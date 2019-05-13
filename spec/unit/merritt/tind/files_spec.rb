require 'spec_helper'
require 'English'

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

      it 'locks the file' do
        filename = File.join(tmpdir, 'file.bin')
        startfile = File.join(tmpdir, 'start.bin')
        stopfile = File.join(tmpdir, 'stop.bin')

        locking_process_id = fork do
          Files.with_lock(filename) do |_|
            File.open(startfile, 'w') { |f| f.puts('start') }
            loop { File.exist?(stopfile) ? break : sleep(0.1) }
          end
        end

        contending_process_id = fork do
          loop { File.exist?(startfile) ? break : sleep(0.1) }
          File.open(filename, 'a+t') do |f|
            begin
              can_lock = f.flock(File::LOCK_EX | File::LOCK_NB)
              test_passed = can_lock.is_a?(FalseClass)
              exit(test_passed ? 0 : 1)
            ensure
              f.flock(File::LOCK_UN) # just in case
            end
          end
        end
        Process.wait(contending_process_id)
        expect($CHILD_STATUS.exitstatus).to eq(0), "expected #{filename} to be locked, but was not"

        File.open(stopfile, 'w') { |f| f.puts('stop') }
        Process.wait(locking_process_id)
        expect($CHILD_STATUS.exitstatus).to eq(0) # just to be sure

        File.open(filename, 'a+t') do |f|
          begin
            can_lock = f.flock(File::LOCK_EX | File::LOCK_NB)
            expect(can_lock).to eq(0), "expected #{filename} to be unlocked, but was locked"
          ensure
            f.flock(File::LOCK_UN)
          end
        end
      end
    end

  end
end
