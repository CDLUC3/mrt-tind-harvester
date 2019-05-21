# ------------------------------------------------------------
# SimpleCov setup

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.command_name 'spec:lib'

  SimpleCov.minimum_coverage 100
  SimpleCov.start do
    add_filter '/spec/'
    formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console
    ]
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
  end
end

# ------------------------------------------------------------
# Rspec configuration

require 'webmock/rspec'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
  config.before(:each) { WebMock.disable_net_connect! }
  config.after(:each) { WebMock.allow_net_connect! }
end

# ------------------------------------------------------------
# Code under test

ENV['HARVESTER_ENV'] = 'test'

require 'merritt'

# TODO: is this needed?
Dir.glob(File.expand_path('support/*.rb', __dir__)).sort.each(&method(:require))
