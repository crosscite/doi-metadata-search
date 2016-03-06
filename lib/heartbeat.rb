require 'sinatra/base'
require 'sidekiq'

module Sinatra
  module Heartbeat
    def services_up?
      [memcached_up?, redis_up?, sidekiq_up?, solr_up?].all?
    end

    def memcached_up?
      memcached_client = Dalli::Client.new
      memcached_client.alive!
      true
    rescue
      false
    end

    def redis_up?
      redis_client = Redis.new
      redis_client.ping == "PONG"
    rescue
      false
    end

    def sidekiq_up?
      sidekiq_client = Sidekiq::ProcessSet.new
      sidekiq_client.size > 0
    rescue
      false
    end

    def solr_up?
      solr_client = RSolr.connect(url: ENV['SOLR_URL'])
      count = solr_client.get ENV['SOLR_SELECT'], params: { q: '*:*', rows: 0 }
      count.fetch('response', {}).fetch('numFound', 0) > 0
    rescue
      false
    end
  end

  helpers Heartbeat
end
