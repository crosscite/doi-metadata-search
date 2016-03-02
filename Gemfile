source 'http://rubygems.org'
ruby '2.3.0'

gem 'dotenv'
gem 'bugsnag'
gem 'awesome_print'
gem 'activesupport'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'haml'
gem 'mongo', '~> 1.12.3'
gem 'multi_json'
gem 'oj'
gem 'bson_ext'
gem 'rsolr'
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'bson'
gem 'maremma'
gem 'gabba'
gem 'dalli'
gem 'omniauth-orcid'
gem 'omniauth-jwt', '~> 0.0.3', git: 'https://github.com/datacite/omniauth-jwt.git'
gem 'rack-flash3'
gem 'oauth2'
gem 'sidekiq', '~> 3.5.3'
gem 'nokogiri'
gem 'sanitize'
gem 'rake'
gem 'log4r'
gem 'namae'
gem 'sass'
gem 'whenever', require: false

group :development do
  gem 'capistrano', '~> 3.4.0'
  gem 'capistrano-passenger', '~> 0.1.1'
  gem 'capistrano-bundler', '~> 1.1.2', require: false
  gem 'capistrano-npm', '~> 1.0.0'
end

group :test do
  gem 'rspec'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'factory_girl'
  gem 'poltergeist'
  gem 'webmock', '~> 1.20.0'
  gem 'vcr', '~> 2.9.3'
  gem 'codeclimate-test-reporter', require: nil
end

group :test, :development do
  gem 'rubocop', '~> 0.27.0', require: false
end
