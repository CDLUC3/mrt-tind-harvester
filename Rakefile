# ------------------------------------------------------------
# RSpec

require 'rspec/core'
require 'rspec/core/rake_task'

namespace :spec do

  desc 'Run all unit tests'
  RSpec::Core::RakeTask.new(:unit) do |task|
    task.rspec_opts = %w[--color --format documentation --order default]
    task.pattern = 'unit/**/*_spec.rb'
  end

  desc 'Run all database tests'
  RSpec::Core::RakeTask.new(:db) do |task|
    task.rspec_opts = %w[--color --format documentation --order default]
    task.pattern = 'db/**/*_spec.rb'
  end

  task all: %i[unit db]
end

desc 'Run all tests'
task spec: 'spec:all'

# ------------------------------------------------------------
# Coverage

desc 'Run all tests with coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].invoke
end

# ------------------------------------------------------------
# RuboCop

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# ------------------------------------------------------------
# Standalone Migrations
require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks

# ------------------------------------------------------------
# Defaults

desc 'Run unit tests, check test coverage, run acceptance tests, check code style'
task default: %i[coverage rubocop]
