ENV['RACK_ENV'] = 'test'

# set up Code Climate
require 'simplecov'
SimpleCov.start

require 'sinatra'
require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'vcr'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'capybara-screenshot/rspec'
require 'tilt/haml'

require File.join(File.dirname(__FILE__), '..', 'app.rb')

def file_fixture(name)
  File.new(File.join(File.dirname(__FILE__), "/fixtures/#{name}"))
end

# require support files, and files in lib folder
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), '../lib/**/*.rb')].each { |f| require f }

config_file "config/#{ENV['RA']}.yml"

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

Capybara.app = app

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.order = :random
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    timeout: 60,
    inspector: true,
    debug: false,
    window_size: [1024, 768]
  })
end

Capybara.javascript_driver = :poltergeist
Capybara.default_selector = :css
Capybara::Screenshot.prune_strategy = :keep_last_run

Capybara.configure do |config|
  config.match = :prefer_exact
  config.ignore_hidden_elements = true
end

WebMock.disable_net_connect!(
  allow: ['codeclimate.com:443', ENV['PRIVATE_IP'], ENV['HOSTNAME']],
  allow_localhost: true
)

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.ignore_localhost = true
  c.ignore_hosts 'codeclimate.com'
  c.filter_sensitive_data('<ORCID_UPDATE_KEY>') { ENV['ORCID_UPDATE_KEY'] }
  c.filter_sensitive_data('<ORCID_UPDATE_TOKEN>') { ENV['ORCID_UPDATE_TOKEN'] }
  c.allow_http_connections_when_no_cassette = false
  c.configure_rspec_metadata!


  record_mode = ENV["VCR"] ? ENV["VCR"].to_sym : :once
  c.default_cassette_options = { :record => record_mode }
end

def capture_stdout(&block)
  stdout, string = $stdout, StringIO.new
  $stdout = string

  yield

  string.tap(&:rewind).read
ensure
  $stdout = stdout
end
