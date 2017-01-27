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
                 include: 'data-center,resource-type,work-type,member,registration-agency',
                 'resource-type-id' => params.fetch('resource-type-id', nil),
                 'relation-type-id' => params.fetch('relation-type-id', nil),
                 'data-center-id' => params.fetch('data-center-id', nil),
                 'member-id' => params.fetch('member-id', nil),
                 'source-id' => params.fetch('source-id', nil) }.compact
      url = "#{ENV['API_URL']}/works?" + URI.encode_www_form(params)

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_relations(params = {})
      params = { "work-id" => params.fetch("work-id", nil),
                 "relation-type-id" => params.fetch("relation-type-id", nil),
                 "source-id" => params.fetch("source-id", nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 include: 'relation-type,data-center' }.compact
      url = "#{ENV['API_URL']}/relations?" + URI.encode_www_form(params)

      response = Maremma.get url, timeout: TIMEOUT
      { data: Array(response.body.fetch("data", [])),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_people(params = {})
      params = { id: params.fetch(:id, nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 query: params.fetch(:query, nil) }.compact
      url = "#{ENV['API_URL']}/people?" + URI.encode_www_form(params)

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_contributions(params = {})
      params = { "person-id" => params.fetch("person-id", nil),
                 "work-id" => params.fetch("work-id", nil),
                 "source-id" => params.fetch("source-id", nil),
                 "data-center-id" => params.fetch("data-center-id", nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 include: 'data-center' }.compact
      url = "#{ENV['API_URL']}/contributions?" + URI.encode_www_form(params)

      response = Maremma.get url, timeout: TIMEOUT
      { data: Array(response.body.fetch("data", [])),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_datacenters(params = {})
      params = { id: params.fetch(:id, nil),
                 ids: params.fetch(:ids, nil),
                 offset: params.fetch(:offset, 0),
                 rows: params.fetch(:rows, 25),
                 query: params.fetch(:query, nil),
                 year: params.fetch(:year, nil),
                 include: 'member,registration-agency',
                 "member-id" => params.fetch("member-id", nil),
                 "registration-agency-id" => "datacite" }.compact
      url = "#{ENV['API_URL']}/data-centers?" + URI.encode_www_form(params)

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_members(params = {})
      params = { id: params.fetch(:id, nil),
                 'member-type' => params.fetch('member-type', nil),
                 region: params.fetch(:region, nil),
                 year: params.fetch(:year, nil),
                 query: params.fetch(:query, nil) }.compact
      url = "#{ENV['API_URL']}/members?" + URI.encode_www_form(params)

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def get_sources(params = {})
      params = { id: params.fetch(:id, nil),
                 query: params.fetch(:query, nil),
                 include: 'group',
                 'group-id' => params.fetch('group-id', nil) }.compact
      url = "#{ENV['API_URL']}/sources?" + URI.encode_www_form(params)

      response = Maremma.get url, timeout: TIMEOUT
      { data: response.body.fetch("data", []),
        included: response.body.fetch("included", []),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end
  end

  helpers Api
end
