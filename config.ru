Encoding.default_external = Encoding::UTF_8

ENV['SINATRA_ACTIVESUPPORT_WARNING'] = 'false'

require 'rubygems'
require 'bundler'

Bundler.require
require './app.rb'

# CORS support
use Rack::Cors do
  allow do
    origins '*'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

run Sinatra::Application
