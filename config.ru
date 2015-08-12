require 'rubygems'
require 'bundler'

Bundler.require

require './app'
require './heartbeat'

# from https://github.com/mperham/sidekiq/wiki/Monitoring
require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :size => 1 }
end

require 'sidekiq/web'
Sidekiq::Web.use Rack::Session::Cookie, :secret => ENV['RACK_SESSION_COOKIE']
map '/sidekiq' do
  use Rack::Auth::Basic, "Sidekiq Web" do |username, password|
    username == ENV['ADMIN_USERNAME'] && password == ENV['ADMIN_PASSWORD']
  end

  run Sidekiq::Web
end

Sidekiq::Web.instance_eval { @middleware.reverse! } # Last added, First Run

run Rack::URLMap.new({
  '/' => Sinatra::Application,
  '/heartbeat' => Heartbeat,
  '/sidekiq' => Sidekiq::Web
})
