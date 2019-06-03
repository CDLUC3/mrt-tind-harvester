$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'merritt/tind/module_info'

Gem::Specification.new do |s|
  s.name = Merritt::TIND::NAME
  s.version = Merritt::TIND::VERSION
  s.authors = ['David Moles']
  s.email = ['david.moles@ucop.edu']
  s.summary = 'TIND harvester for Merritt'
  s.description = 'Harvests TIND OAI-PMH feed to identify files for ingest into Merritt'
  s.license = 'MIT'

  s.required_ruby_version = '~> 2.4'

  s.homepage = 'https://github.com/CDLUC3/mrt-tind-harvester'
  s.files = Dir.glob('lib/**/*.rb') + Dir.glob('bin/*')
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_dependency 'mrt-ingest', '~> 0.0.5'
  s.add_dependency 'mysql2', '~> 0.4.0' # TODO: update to 0.5 when UI does
  s.add_dependency 'nokogiri', '~> 1.10'
  s.add_dependency 'oai', '~> 0.4'
  s.add_dependency 'rest-client', '~> 2.0'

  s.add_development_dependency 'capistrano', '~> 3.4'
  s.add_development_dependency 'capistrano-bundler', '~> 1.1'
  s.add_development_dependency 'database_cleaner', '~> 1.5'
  s.add_development_dependency 'factory_bot', '~> 4.11'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rubocop', '~> 0.69'
  s.add_development_dependency 'rubocop-rspec', '~> 1.33'
  s.add_development_dependency 'simplecov', '~> 0.16'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'standalone_migrations', '~> 5.2'
  s.add_development_dependency 'webmock', '~> 3.5'
end
