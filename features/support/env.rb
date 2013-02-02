ENV['RACK_ENV'] = 'test'

require File.join(File.dirname(__FILE__), '..', '..', 'app.rb')

require 'capybara'
require 'capybara/cucumber'
require 'capybara/poltergeist'
require 'rspec'

Capybara.javascript_driver = :poltergeist

Capybara.app = Sinatra::Application

World do
  include RSpec::Expectations
  include RSpec::Matchers
end