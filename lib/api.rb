require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Api
    def get_works(params = {})
      params = { id: params.fetch(:id, nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 sort: params.fetch(:sort, nil),
                 query: params.fetch(:query, nil),
                 year: params.fetch('year', nil),
                 include: 'publisher,resource-type,work-type,member,registration-agency',
                 'resource-type-id' => params.fetch('resource-type-id', nil),
                 'relation-type-id' => params.fetch('relation-type-id', nil),
                 'publisher-id' => params.fetch('publisher-id', nil),
                 'member-id' => params.fetch('member-id', nil),
                 'source-id' => params.fetch('source-id', nil) }.compact
      url = "#{ENV['API_URL']}/works?" + URI.encode_www_form(params)

      result = Maremma.get url, timeout: 10
      { data: result.fetch("data", []),
        included: result.fetch("included", []),
        errors: Array(result.fetch("errors", [])),
        meta: result.fetch("meta", {}) }
    end

    def get_relations(params = {})
      params = { "work-id" => params.fetch("work-id", nil),
                 "relation-type-id" => params.fetch("relation-type-id", nil),
                 "source-id" => params.fetch("source-id", nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 include: 'relation-type,source,publisher' }.compact
      url = "#{ENV['API_URL']}/relations?" + URI.encode_www_form(params)

      result = Maremma.get url, timeout: 10
      { data: Array(result.fetch("data", [])),
        included: result.fetch("included", []),
        errors: Array(result.fetch("errors", [])),
        meta: result.fetch("meta", {}) }
    end

    def get_contributors(params = {})
      params = { id: params.fetch(:id, nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 query: params.fetch(:query, nil) }.compact
      url = "#{ENV['API_URL']}/contributors?" + URI.encode_www_form(params)

      result = Maremma.get url, timeout: 10
      { data: result.fetch("data", []),
        errors: Array(result.fetch("errors", [])),
        meta: result.fetch("meta", {}) }
    end

    def get_contributions(params = {})
      params = { "contributor-id" => params.fetch("contributor-id", nil),
                 "work-id" => params.fetch("work-id", nil),
                 "source-id" => params.fetch("source-id", nil),
                 "publisher-id" => params.fetch("publisher-id", nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 include: 'publisher,source' }.compact
      url = "#{ENV['API_URL']}/contributions?" + URI.encode_www_form(params)

      result = Maremma.get url, timeout: 10
      { data: Array(result.fetch("data", [])),
        included: result.fetch("included", []),
        errors: Array(result.fetch("errors", [])),
        meta: result.fetch("meta", {}) }
    end

    def get_datacenters(params = {})
      params = { id: params.fetch(:id, nil),
                 ids: params.fetch(:ids, nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 query: params.fetch(:query, nil),
                 include: 'member,registration-agency',
                 "member-id" => params.fetch("member-id", nil),
                 'registration-agency-id': "datacite" }.compact
      url = "#{ENV['API_URL']}/publishers?" + URI.encode_www_form(params)

      result = Maremma.get url, timeout: 10
      { data: result.fetch("data", []),
        included: result.fetch("included", []),
        errors: Array(result.fetch("errors", [])),
        meta: result.fetch("meta", {}) }
    end

    def get_members(params = {})
      params = { id: params.fetch(:id, nil),
                 'member-type' => params.fetch('member-type', nil),
                 region: params.fetch(:region, nil),
                 year: params.fetch(:year, nil),
                 query: params.fetch(:query, nil) }.compact
      url = "#{ENV['API_URL']}/members?" + URI.encode_www_form(params)

      result = Maremma.get url, timeout: 10
      { data: result.fetch("data", []),
        errors: Array(result.fetch("errors", [])),
        meta: result.fetch("meta", {}) }
    end

    def get_sources(params = {})
      params = { id: params.fetch(:id, nil),
                 query: params.fetch(:query, nil),
                 include: 'group',
                 'group-id' => params.fetch('group-id', nil) }.compact
      url = "#{ENV['API_URL']}/sources?" + URI.encode_www_form(params)

      result = Maremma.get url, timeout: 10
      { data: result.fetch("data", []),
        included: result.fetch("included", []),
        errors: Array(result.fetch("errors", [])),
        meta: result.fetch("meta", {}) }
    end
  end

  helpers Api
end
