require 'sinatra/base'
require 'json'

module Sinatra
  module Stats
    def count_result
      settings.solr.get ENV['SOLR_SELECT'], params: {
        q: '*:*',
        fq: 'has_metadata:true',
        rows: 0
      }
    end

    def dataset_result
      settings.solr.get ENV['SOLR_SELECT'], params: {
        q: 'resourceTypeGeneral:Dataset',
        rows: 0
      }
    end

    def text_result
      settings.solr.get ENV['SOLR_SELECT'], params: {
        q: 'resourceTypeGeneral:Text',
        rows: 0
      }
    end

    def software_result
      settings.solr.get ENV['SOLR_SELECT'], params: {
        q: 'resourceTypeGeneral:Software',
        rows: 0
      }
    end

    def oldest_result
      settings.solr.get ENV['SOLR_SELECT'], params: {
        q: 'publicationYear:[1 TO *]',
        rows: 1,
        sort: 'publicationYear asc'
      }
    end

    def count_stats
      { value: count_result['response']['numFound'],
        name: 'Total number of indexed DOIs',
        number: true }
    end

    def dataset_stats
      { value: dataset_result['response']['numFound'],
        name: 'Number of indexed datasets',
        number: true }
    end

    def text_stats
      { value: text_result['response']['numFound'],
        name: 'Number of indexed text documents',
        number: true }
    end

    def software_stats
      { value: software_result['response']['numFound'],
        name: 'Number of indexed software packages',
        number: true }
    end

    def oldest_stats
      { value: oldest_result['response']['docs'].first['publicationYear'],
        name: 'Oldest indexed publication year' }
    end

    def orcid_stats
      { value: MongoData.coll('orcids').count(query: { updated: true }),
        name: 'Number of ORCID records updated' }
    end

    def stats
      [count_stats, dataset_stats, text_stats, software_stats, oldest_stats, orcid_stats]
    end
  end
end
