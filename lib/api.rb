require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Api
    def get_works(params = {})
      params = { id: params.fetch(:id, nil),
                 offset: params.fetch(:offset, 0),
                 rows: 25,
                 q: params.fetch(:q, nil),
                 'resource-type-id' => params.fetch('resource-type-id', nil),
                 year: params.fetch('year', nil),
                 'publisher-id' => params.fetch('publisher-id', nil),
                 'member-id' => params.fetch('member-id', nil) }.compact
      url = "#{ENV['API_URL']}/works?" + URI.encode_www_form(params)

      result = Maremma.get url
      { data: result.fetch("data", []), meta: result.fetch("meta", {}) }
    end

    def get_contributors(params = {})
      params = { id: params.fetch(:id, nil),
                 offset: params.fetch(:offset, 0),
                 rows: 25,
                 q: params.fetch(:q, nil) }.compact
      url = "#{ENV['API_URL']}/contributors?" + URI.encode_www_form(params)

      result = Maremma.get url
      { data: result.fetch("data", []), meta: result.fetch("meta", {}) }
    end

    def get_contributions(params = {})
      params = { "contributor-id" => params.fetch("contributor-id", nil),
                 offset: params.fetch(:offset, 0),
                 rows: 25 }.compact
      url = "#{ENV['API_URL']}/contributions?" + URI.encode_www_form(params)

      result = Maremma.get url
      { data: result.fetch("data", []), meta: result.fetch("meta", {}) }
    end

    def get_datacenters(params = {})
      params = { id: params.fetch(:id, nil),
                 offset: params.fetch(:offset, 0),
                 rows: 25,
                 q: params.fetch(:q, nil),
                 'registration-agency-id': "datacite" }.compact
      url = "#{ENV['API_URL']}/publishers?" + URI.encode_www_form(params)

      result = Maremma.get url
      { data: result.fetch("data", []), meta: result.fetch("meta", {}) }
    end

    def get_members(params = {})
      params = { id: params.fetch(:id, nil),
                 'member-type' => params.fetch('member-type', nil),
                 region: params.fetch(:region, nil),
                 year: params.fetch(:year, nil),
                 q: params.fetch(:q, nil) }.compact
      url = "#{ENV['API_URL']}/members?" + URI.encode_www_form(params)

      result = Maremma.get url
      { data: result.fetch("data", []), meta: result.fetch("meta", {}) }
    end
  end

  helpers Api
end
