source "http://rubygems.org"

gem "dotenv"
gem "sentry-raven", "~> 2.9"
gem "awesome_print"
gem "activesupport"
gem "actionpack"
gem "sinatra"
gem "sinatra-contrib"
gem "haml"
gem "will_paginate"
gem "will_paginate-bootstrap", git: "https://github.com/HeyPublisher/will_paginate-bootstrap"
gem "iso8601", "~> 0.9.0"
gem "maremma", "~> 4.5"
gem "gabba"
gem "jwt"
gem "rack-flash3"
gem "rack-cors", "~> 1.0", require: "rack/cors"
gem "nokogiri"
gem "oj", ">= 2.8.3"
gem "oj_mimic_json", "~> 1.0", ">= 1.0.1"
gem "sanitize"
gem "rake"
gem "namae"
gem "sass"
gem "gon-sinatra"
gem "git", "~> 1.5"
gem "logstash-logger", "~> 0.26.1"
gem 'crawler_detect'



group :development do
  gem "better_errors"
  gem "binding_of_caller"
end

group :test do
  gem "rspec"
  gem "capybara"
  gem "capybara-screenshot"
  gem "factory_girl"
  gem "cuprite"
  gem "webmock", "~> 3.5.1"
  gem "vcr", "~> 2.9.3"
  gem "codeclimate-test-reporter", "~> 1.0.0"
  gem "simplecov"
  gem 'crawler_detect'
end

group :test, :development do
  gem "rubocop", "~> 0.77.0"
  gem "rubocop-performance", "~> 1.5", ">= 1.5.1"
end
