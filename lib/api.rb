require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Api
    include Sinatra::Helpers

    def get_works(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/works/#{params[:id]}?include=data-center,resource-type,member,citation-events,reference-events"
      else
        params = { id: params.fetch(:id, nil),
                   'page[number]' => params.fetch('page[number]', 1),
                   'page[size]' => params.fetch('page[size]', 25),
                   ids: params.fetch(:ids, nil),
                   sort: params.fetch(:sort, nil),
                   query: params.fetch(:query, nil),
                   year: params.fetch('year', nil),
                   registered: params.fetch('registered', nil),
                   include: 'data-center,resource-type,member',
                   'resource-type-id' => params.fetch('resource-type-id', nil),
                   'data-center-id' => params.fetch('data-center-id', nil),
                   'member-id' => params.fetch('member-id', nil),
                   'affiliation-id' => params.fetch('affiliation-id', nil),
                   'work-id' => params.fetch('work-id', nil),
                   'person-id' => params.fetch('person-id', nil),
                   'has-views' => params.fetch('has-views', nil),
                   'has-downloads' => params.fetch('has-downloads', nil),
                   'has-citations' => params.fetch('has-citations', nil) }.compact

        url = "#{ENV['API_URL']}/works?" + URI.encode_www_form(params)
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
        url = "#{ENV['API_URL']}/data-centers/#{params.fetch(:id)}?include=member"
      else
        params = { id: params.fetch(:id, nil),
                   ids: params.fetch(:ids, nil),
                   'page[number]' => params.fetch('page[number]', 1),
                   'page[size]' => params.fetch('page[size]', 25),
                   query: params.fetch(:query, nil),
                   year: params.fetch(:year, nil),
                   registered: params.fetch(:registered, nil),
                   include: 'member',
                   "member-id" => params.fetch("member-id", nil) }.compact
        url = "#{ENV['API_URL']}/data-centers?" + URI.encode_www_form(params)
      end

      response = Maremma.get(url, timeout: TIMEOUT)
      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_members(params = {})
      if params.fetch(:id, nil).present?
        url = "#{ENV['API_URL']}/members/#{params.fetch(:id)}"
      else
        params = { id: params.fetch(:id, nil),
                   'member-type' => params.fetch('member-type', nil),
                   region: params.fetch(:region, nil),
                   year: params.fetch(:year, nil),
                   query: params.fetch(:query, nil) }.compact
        url = "#{ENV['API_URL']}/members?" + URI.encode_www_form(params)
      end

      response = Maremma.get(url, timeout: TIMEOUT)
      { data: response.body.fetch("data", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_events(params = {})
      aggregations = "metrics_aggregations"    
      params =
      {
        id:                   params.fetch(:id, nil),
        'subj-id'          => params.fetch('subj-id', nil),
        'obj-id'           => params.fetch('obj-id', nil),
        'doi'              => params.fetch('doi', nil),
        'occurredAt'       => params.fetch('occurred_in', nil), 
        'include'          => params.fetch('include', nil), 
        'page[number]'     => params.fetch('page[number]', nil), 
        'page[size]'       => params.fetch('page[size]', nil), 
        'sort'             => params.fetch('sort', nil), 
        'aggregations'     => aggregations, 
        # 'source-id'        => params.fetch('sourceId', INCLUDED_SOURCES.join(',')), 
        'extra'            => true,
        query: params.fetch(:query, nil)
      }.compact
      url = "#{ENV['API_URL']}/events?" + URI.encode_www_form(params)

      response = params[:response].present? ? params[:response] : Maremma.get(url, headers: {"Accept"=> "application/vnd.api+json; version=2"}, timeout: TIMEOUT)
      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        links: Array(response.body.fetch("links", [])),
        meta: response.body.fetch("meta", {}) }
    end  
  end

  helpers Api
end
