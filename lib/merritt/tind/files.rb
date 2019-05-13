require 'timeout'

module Merritt
  module TIND
    module Files
      DEFAULT_TIMEOUT_SECS = 5
      DEFAULT_SLEEP_INTERVAL_SECS = 0.25

      class << self

        def with_lock(filename, timeout_s = DEFAULT_TIMEOUT_SECS, sleep_s = DEFAULT_SLEEP_INTERVAL_SECS)
          f = acquire_lock(filename, timeout_s, sleep_s)
          yield f
        ensure
          f.flock(File::LOCK_UN)
        end

        private

        def acquire_lock(filename, timeout_s, sleep_s)
          Timeout.timeout(timeout_s) do
            loop do
              f = File.open(filename, 'a+t')
              f.flock(File::LOCK_EX)
              return f if File.identical?(filename, f)

              f.flock(File::LOCK_UN)
              sleep(sleep_s)
            end
          end
        end

      end
    end
  end
end
