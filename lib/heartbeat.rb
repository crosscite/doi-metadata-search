require 'sinatra/base'

module Sinatra
  module Heartbeat
    def services_up?
      [solr_up?].all?
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
