$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'big_query_log_viewer/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'big_query_log_viewer'
  s.version     = BigQueryLogViewer::VERSION
  s.authors     = ['Zach Schneider']
  s.email       = ['zach@aha.io']
  s.homepage    = 'https://github.com/aha-app/bigquery-log-viewer'
  s.summary     = 'A simple Rails engine and React app to search logs stored in Google BigQuery.'
  s.description = 'A simple Rails engine and React app to search logs stored in Google BigQuery.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,lib}/**/*', 'LICENSE.txt', 'Rakefile', 'README.md']

  s.add_dependency 'rails'
  s.add_dependency 'therubyracer'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'react-rails'
  s.add_dependency 'less-rails'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'sprockets-coffee-react'
  s.add_dependency 'less-rails-bootstrap'

  s.add_development_dependency 'coffeelint'
end
