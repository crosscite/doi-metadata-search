require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Lagottino


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
      usage_metrics = merge_metrics(items, metrics.dig(:meta, 'doisUsageTypes'))
      merge_metrics(usage_metrics, metrics.dig(:meta, 'doisRelationTypes'))
    end

    def normalize_doi(doi)
      doi = Array(/\A(?:(http|https):\/(\/)?(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(doi)).last
      doi = doi.delete("\u200B").downcase if doi.present?
      "https://doi.org/#{doi}" if doi.present?
    end

    def call_metrics dois, options={}

      url = "#{ENV['API_URL']}/events?doi=#{dois.join(",")}&" + URI.encode_www_form({"extra"=> true,"aggregations"=>"query_aggregations,metrics_aggregations", "page[size]"=> 25})
      puts url
      # dependency injection
      response = options[:response].present? ? options[:response] : Maremma.get(url, headers: {"Accept"=> "application/vnd.api+json; version=2"}, timeout: 20)
     {
        data: Array(response.body.fetch("data", [])),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) 
      }
    end

    def merge_metrics(items, metrics)
      items.map do |item|
        doi = normalize_doi(item.fetch('attributes', {}).fetch('doi', "item"))
        metric = Array(metrics).find { |c| c.fetch('id', {}) == doi } || {}
        item["metrics"] = transform_metrics_array(metric.fetch("relationTypes",[]))
        item
      end
    end
  end
  helpers Lagottino
end
