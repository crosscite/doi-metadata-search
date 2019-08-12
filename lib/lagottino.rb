require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Lagottino
    include Sinatra::Helpers

    def get_metrics(items)
      return [] if items.empty?

      dois = items.reduce([]) do |sum, item|
        # if item.is_a?(Hash) && item.fetch("attributes", {}).fetch("registration-agency-id", nil) == ENV['RA']
        if item.is_a?(Hash)
          sum << item.fetch("attributes", {}).fetch("doi", nil)
        else
          sum
        end
      end.compact
      metrics = call_metrics(dois)
 
      items.map! do |item|
        item.merge!({"metrics"=>{}})
        item["metrics"].merge!(merge_metrics(item, metrics.dig(:meta, 'doisUsageTypes')))
        item["metrics"].merge!(merge_citations(item, metrics.dig(:meta, 'uniqueCitations')))
        item
      end
    end

    def normalize_doi(doi)
      doi = Array(/\A(?:(http|https):\/(\/)?(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(doi)).last
      doi = doi.delete("\u200B").downcase if doi.present?
      "https://doi.org/#{doi}" if doi.present?
    end

    def call_metrics dois, options={}
      relations = INCLUDED_RELATION_TYPES + USAGE_RELATION_TYPES 
      params = {
        "extra"            => true,
        'source-id'        => INCLUDED_SOURCES.join(','), 
        'relation-type-id' => relations.join(','),
        "aggregations"     => "query_aggregations,metrics_aggregations", 
        "page[size]"       => 25
      }

      url = "#{ENV['API_URL']}/events?doi=#{dois.join(",")}&" + URI.encode_www_form(params)
      puts url
      # dependency injection
      response = options[:response].present? ? options[:response] : Maremma.get(url, headers: {"Accept"=> "application/vnd.api+json; version=2"}, timeout: 20)
     {
        data: Array(response.body.fetch("data", [])),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) 
      }
    end

    def merge_metrics(item, metrics)
      doi = normalize_doi(item.fetch('attributes', {}).fetch('doi', "item"))
      metric_hash = Array(metrics).find { |c| c.fetch('id', {}) == doi } || {}
      transform_metrics_array(metric_hash.fetch("relationTypes",[]))
    end

    def merge_citations(item, metrics)
      doi = (item.fetch('attributes', {}).fetch('doi', "item"))
      metric_hash = Array(metrics).find { |c| c.fetch('id', {}) == doi } || {}
      {citations: metric_hash}
    end
  end
  helpers Lagottino
end
