ENV['RACK_ENV'] = 'test'

require File.join(File.dirname(__FILE__), '..', '..', 'app.rb')

require 'capybara'
require 'capybara/cucumber'
require 'capybara/poltergeist'
require 'rspec'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, { :timeout => 90 })
end

Capybara.javascript_driver = :poltergeist

Capybara.app = Sinatra::Application

World do
  include RSpec::Expectations
  include RSpec::Matchers
end