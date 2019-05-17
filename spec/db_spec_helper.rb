require 'spec_helper'
require 'active_record'
require 'database_cleaner'
require 'factory_bot'

Dir.glob(File.expand_path('models/*.rb', __dir__)).sort.each(&method(:require))
Dir.glob(File.expand_path('support/*.rb', __dir__)).sort.each(&method(:require))

def check_connection_config!
  db_config = YAML.load_file('spec/config/database.yml')['test'].map { |k, v| [k.to_sym, v] }.to_h
  host = db_config[:host]
  raise("Can't run destructive tests against non-local database #{host || 'nil'}") unless host == 'localhost'

  puts "Using database #{db_config[:database]} on host #{host} with username #{db_config[:username]}"
  ActiveRecord::Base.establish_connection(db_config)
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    check_connection_config!
    FactoryBot.find_definitions
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

# Dir.glob(File.expand_path('factories/*.rb', __dir__)).sort.each(&method(:require))
