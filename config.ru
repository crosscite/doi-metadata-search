require 'rubygems'
require 'bundler'

Bundler.require

require './app'
require './heartbeat'
require 'sidekiq/web'

Sidekiq::Web.use Rack::Session::Cookie, :secret => ENV['RACK_SESSION_COOKIE']
Sidekiq::Web.instance_eval { @middleware.reverse! } # Last added, First Run

run Rack::URLMap.new({
  '/' => Sinatra::Application,
  '/heartbeat' => Heartbeat,
  '/sidekiq' => Sidekiq::Web
})
