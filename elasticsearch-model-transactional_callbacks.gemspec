# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'elasticsearch/model/transactional_callbacks/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'elasticsearch-model-transactional_callbacks'
  spec.version     = Elasticsearch::Model::TransactionalCallbacks::VERSION
  spec.authors     = ['Ignatius Reza']
  spec.email       = ['lyoneil.de.sire@gmail.com']
  spec.homepage    = 'https://github.com/ignatiusreza/elasticsearch-model-transactional_callbacks'
  spec.summary     = 'Extend ElasticSearch::Model with transactional callbacks for asynchronous indexing'
  spec.description = 'Reduce load from your application server by offloading indexing into background jobs'
  spec.license     = 'MIT'

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'elasticsearch-model', '>= 5.0.0'
  spec.add_dependency 'rails', '>= 5.0.0'

  spec.add_development_dependency 'minitest-ci'
  spec.add_development_dependency 'minitest-stub_any_instance'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'sqlite3', '~> 1.3.6'
end
