require 'timeout'

module Merritt
  module TIND
    module Files
      DEFAULT_TIMEOUT_SECS = 5
      DEFAULT_SLEEP_INTERVAL_SECS = 0.1

      class << self

        def with_lock(filename)
          f = acquire_lock(filename)
          yield f
        ensure
          f.flock(File::LOCK_UN) if f
        end

        def rotate_and_lock(filename)
          with_lock(filename) do |f|
            if File.size?(filename)
              rotating(filename) { |f1| yield f1 }
            else
              yield f
            end
          end
        end

        private

        def rotating(filename)
          rotate_to = rotated_name(filename)

          File.rename(filename, rotate_to)
          with_lock(filename) { |f| yield f }
        end

        def rotated_name(filename)
          loop do
            renamed_file = filename + '-' + Time.now.utc.iso8601(3)
            return renamed_file unless File.exist?(renamed_file)

            sleep(DEFAULT_SLEEP_INTERVAL_SECS)
          end
        end

        def acquire_lock(filename)
          Timeout.timeout(DEFAULT_TIMEOUT_SECS) do
            loop do
              f = File.open(filename, 'a+')
              f.flock(File::LOCK_EX)
              return f if File.identical?(filename, f)

              # we do cover this, but it's called in a subprocess
              # so SimpleCov can't tell we've called it
              # :nocov:
              f.flock(File::LOCK_UN)
              sleep(DEFAULT_SLEEP_INTERVAL_SECS)
              # :nocov:
            end
          end
        end

      end
    end
  end
end
