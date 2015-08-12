require 'net/smtp'
require 'timeout'
require 'mongo'

require_relative 'lib/version'

class Heartbeat < Sinatra::Base
  get '' do
    content_type :json

    { services: services,
      version: ::App::VERSION,
      status: human_status(services_up?) }.to_json
  end

  def services
    { mongo: human_status(mongo_up?),
      redis: human_status(redis_up?),
      sidekiq: human_status(sidekiq_up?),
      solr: human_status(solr_up?),
      web: human_status(web_up?) }
  end

  def human_status(service)
    service ? "OK" : "failed"
  end

  def services_up?
    [mongo_up?, redis_up?, sidekiq_up?, solr_up?].all?
  end

  def mongo_up?
    mongo_client = Mongo::Connection.new(ENV['DB_HOST'])[ENV['DB_NAME']]
    mongo_client.collections.size > 0
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

  def web_up?
    web_client = Faraday.new(url: "http://#{ENV['HOSTNAME']}")
    response = web_client.get '/'
    response.status == 200
  rescue
    false
  end
end
