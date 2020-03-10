require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Api
    include Sinatra::Helpers

    def get_works(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/dois/#{params[:id]}?include=client,citation-events,reference-events"
      else
        params = { id: params.fetch(:id, nil),
                   'page[number]' => params.fetch('page[number]', 1),
                   'page[size]' => params.fetch('page[size]', 25),
                   ids: params.fetch(:ids, nil),
                   sort: params.fetch(:sort, nil),
                   query: params.fetch(:query, nil),
                   year: params.fetch('year', nil),
                   registered: params.fetch('registered', nil),
                   include: 'client',
                   'resource-type-id' => params.fetch('resource-type-id', nil),
                   'client-id' => params.fetch('data-center-id', nil),
                   'provider-id' => params.fetch('member-id', nil),
                   'affiliation-id' => params.fetch('affiliation-id', nil),
                   'has-views' => params.fetch('has-views', nil),
                   'has-downloads' => params.fetch('has-downloads', nil),
                   'has-citations' => params.fetch('has-citations', nil) }.compact

        url = "#{ENV['API_URL']}/dois?" + URI.encode_www_form(params)
      end
      response = Maremma.get(url, timeout: TIMEOUT)

      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_people(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['VOLPINO_URL']}/users/" + params.fetch(:id)
      else
        params = { id: params.fetch(:id, nil),
                   'page[number]' => params.fetch('page[number]', 1),
                   'page[size]' => params.fetch('page[size]', 25),
                   query: params.fetch(:query, nil) }.compact
        url = "#{ENV['VOLPINO_URL']}/users?" + URI.encode_www_form(params)
      end

      response = Maremma.get(url, timeout: TIMEOUT)
      { data: response.body.fetch("data", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_datacenters(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/repositories/#{params.fetch(:id)}?include=member"
      else
        params = { id: params.fetch(:id, nil),
                   ids: params.fetch(:ids, nil),
                   'page[number]' => params.fetch('page[number]', 1),
                   'page[size]' => params.fetch('page[size]', 25),
                   query: params.fetch(:query, nil),
                   year: params.fetch(:year, nil),
                   registered: params.fetch(:registered, nil),
                   include: 'provider',
                   "provider-id" => params.fetch("member-id", nil) }.compact
        url = "#{ENV['API_URL']}/repositories?" + URI.encode_www_form(params)
      end

      response = Maremma.get(url, timeout: TIMEOUT)
      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_members(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/providers/#{params.fetch(:id)}"
      else
        params = { id: params.fetch(:id, nil),
                   'member-type' => params.fetch('member-type', nil),
                   region: params.fetch(:region, nil),
                   year: params.fetch(:year, nil),
                   query: params.fetch(:query, nil) }.compact
        url = "#{ENV['API_URL']}/providers?" + URI.encode_www_form(params)
      end

      response = Maremma.get(url, timeout: TIMEOUT)
      { data: response.body.fetch("data", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end
  end

  helpers Api
end
