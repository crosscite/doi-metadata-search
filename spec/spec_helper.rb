ENV['RACK_ENV'] = 'test'

require File.join(File.dirname(__FILE__), '..', 'app.rb')

# set up Code Climate
require "codeclimate-test-reporter"
CodeClimate::TestReporter.configure do |config|
  config.logger.level = Logger::WARN
end
CodeClimate::TestReporter.start

require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'vcr'
require 'factory_girl'

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false
set :dump_errors, false
set :show_exceptions, false

def app
  Sinatra::Application
end

RSpec.configure do |c|
  c.include Rack::Test::Methods
  c.order = :random
end

WebMock.disable_net_connect!(
  allow: ['codeclimate.com', ENV['PRIVATE_IP'], ENV['HOSTNAME']],
  allow_localhost: true
)

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.ignore_localhost = true
  c.ignore_hosts 'codeclimate.com'
  c.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
  c.allow_http_connections_when_no_cassette = true
  c.configure_rspec_metadata!
end
