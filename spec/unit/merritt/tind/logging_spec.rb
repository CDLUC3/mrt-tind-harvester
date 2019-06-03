require 'spec_helper'
require 'fileutils'
require 'English'

module Merritt::TIND
  describe Logging do
    attr_reader :tmpdir

    before(:each) do
      @tmpdir = Dir.mktmpdir('files_spec')
    end

    after(:each) do
      FileUtils.remove_dir(tmpdir, true) if tmpdir
    end

    it 'logs to a file' do
      log_path = Pathname.new(tmpdir) + 'test.log'
      logger = Logging.new_logger(log_path)
      msg = 'help I am trapped in a logging factory'
      logger.info(msg)
      log_data = File.read(log_path)
      expect(log_data).to include(msg)
    end

    it 'allows multiple processes to write to the same log file' do
      log_path = Pathname.new(tmpdir) + 'test.log'

      range = (0..2)
      startfiles = range.map { |i| Pathname.new(tmpdir) + "start.#{i}" }
      stopfiles = range.map { |i| Pathname.new(tmpdir) + "stop.#{i}" }
      pids = range.map do |i|
        fork do
          expect(File.exist?(tmpdir)).to be_truthy
          startfile = startfiles[i]
          stopfile = stopfiles[i]
          next_stopfile = stopfiles[(i + 1) % 3]
          logger = Logging.new_logger(log_path)
          loop { File.exist?(startfile) ? break : sleep(0.1) }
          logger.info("process #{i} started")
          FileUtils.touch(next_stopfile)
          loop { File.exist?(stopfile) ? break : sleep(0.1) }
          logger.info("process #{i} exiting")
          exit(0)
        end
      end

      startfiles.each { |f| FileUtils.touch(f) }
      pids.each do |pid|
        Process.wait(pid)
        expect($CHILD_STATUS.exitstatus).to eq(0)
      end

      log_data = File.read(log_path)
      range.each do |i|
        expect(log_data).to match(/process #{i} started$/)
        expect(log_data).to match(/process #{i} exiting/)
      end
    end
  end
end
