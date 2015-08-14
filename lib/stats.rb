require 'sinatra/base'
require 'json'

require_relative 'doi'
require_relative 'session'
require_relative 'paginate'

module Sinatra
  module Stats
    def stats
      count_result = settings.solr.get ENV['SOLR_SELECT'], params: {
        q: '*:*',
        fq: 'has_metadata:true',
        rows: 0
      }
      dataset_result = settings.solr.get ENV['SOLR_SELECT'], params: {
        q: 'resourceTypeGeneral:Dataset',
        rows: 0
      }
      text_result = settings.solr.get ENV['SOLR_SELECT'], params: {
        q: 'resourceTypeGeneral:Text',
        rows: 0
      }
      software_result = settings.solr.get ENV['SOLR_SELECT'], params: {
        q: 'resourceTypeGeneral:Software',
        rows: 0
      }
      oldest_result = settings.solr.get ENV['SOLR_SELECT'], params: {
        q: 'publicationYear:[1 TO *]',
        rows: 1,
        sort: 'publicationYear asc'
      }

      count_stats = {
        value: count_result['response']['numFound'],
        name: 'Total number of indexed DOIs',
        number: true
      }

      dataset_stats = {
        value: dataset_result['response']['numFound'],
        name: 'Number of indexed datasets',
        number: true
      }

      text_stats = {
        value: text_result['response']['numFound'],
        name: 'Number of indexed text documents',
        number: true
      }

      software_stats = {
        value: software_result['response']['numFound'],
        name: 'Number of indexed software packages',
        number: true
      }

      oldest_stats = {
        value: oldest_result['response']['docs'].first['publicationYear'],
        name: 'Oldest indexed publication year'
      }

      orcid_stats = {
        value: MongoData.coll('orcids').count(query: { updated: true }),
        name: 'Number of ORCID profiles updated'
      }

      [count_stats, dataset_stats, text_stats, software_stats, oldest_stats, orcid_stats]
    end
  end
end
