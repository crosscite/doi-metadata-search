ENV['RACK_ENV'] = 'test'

# set up Code Climate
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.configure do |config|
  config.logger.level = Logger::WARN
end
CodeClimate::TestReporter.start

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

# require support files, and files in lib folder
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), '../lib/**/*.rb')].each { |f| require f }

config_file "config/settings.yml"

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

  OmniAuth.config.test_mode = true
  config.before(:each) do
    OmniAuth.config.mock_auth[:jwt] = OmniAuth::AuthHash.new({
      provider: 'jwt',
      uid: '0000-0002-1825-0097',
      info: { 'role' => "admin",
              'name' => "Josiah Carberry" },
      extra: {},
      credentials: { 'expires' => nil,
                     'expires_at' => Time.now + 1.year }
    })
  end
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
Capybara.save_and_open_page_path = "tmp/capybara"
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
  c.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
  c.allow_http_connections_when_no_cassette = false
  c.configure_rspec_metadata!
end

def capture_stdout(&block)
  stdout, string = $stdout, StringIO.new
  $stdout = string

  yield

  string.tap(&:rewind).read
ensure
  $stdout = stdout
end
