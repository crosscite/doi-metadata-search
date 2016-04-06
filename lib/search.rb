require 'sinatra/base'
require 'json'

require_relative 'doi'
require_relative 'lagotto'
require_relative 'volpino'
require_relative 'session_helper'
require_relative "#{ENV['RA']}/search"

module Sinatra
  module Search
    include Sinatra::Doi
    include Sinatra::Lagotto
    include Sinatra::Volpino
    include Sinatra::SessionHelper

    def select(query_params)
      page = query_page
      rows = query_rows
      Sinatra::Application.settings.solr.paginate(page, rows, ENV['SOLR_SELECT'], params: query_params)
    end

    def response_format
      params.fetch('format', nil) == 'json' ? 'json' : 'html'
    end

    def query_page
      params.fetch('page', 1).to_i
    end

    def query_rows
      params.fetch('rows', DEFAULT_ROWS).to_i
    end

    def query_type
      if params['qf']
        { type: params['qf'].to_sym, value: params['q'].strip }
      elsif doi? params['q']
        { type: :doi, value: to_doi(params['q']).downcase }
      elsif short_doi?(params['q']) || very_short_doi?(params['q'])
        { type: :short_doi, value: to_long_doi(params['q']) }
      elsif orcid?(params['q'])
        { type: :orcid, value: params['q'].strip }
      elsif issn? params['q']
        { type: :issn, value: params['q'].strip.upcase }
      elsif urn? params['q']
        { type: :urn, value: params['q'].strip }
      else
        { type: :normal }
      end
    end

    def bare_query
      params['q']
    end

    def facet_query_fields
      Sinatra::Application.settings.facet_fields.select { |field| params.key?(field) }
    end

    def abstract_facet_query
      fq = {}
      facet_query_fields.reduce({}) do |sum, field|
        params[field].split(';').each do |val|
          fq[field] ||= []
          fq[field] << val
        end
      end
      fq
    end

    def facet_query
      fq = ['has_metadata:true']
      abstract_facet_query.each_pair do |name, values|
        values.each do |value|
          fq << "#{name}: \"#{value}\""
        end
      end
      fq
    end

    def facet_results(solr_result)
      return {} if solr_result['facet_counts'].nil?

      solr_result.fetch('facet_counts', {}).fetch('facet_fields', [])
    end

    def facet_link_not(field_name, field_value)
      fq = abstract_facet_query
      fq[field_name].delete field_value
      fq.delete(field_name) if fq[field_name].empty?

      link = "#{request.path_info}?q=#{CGI.escape(params['q'])}"
      fq.each_pair do |field, vals|
        link += "&#{field}=#{CGI.escape(vals.join(';'))}"
      end
      link
    end

    def facet_link(field_name, field_value)
      fq = abstract_facet_query
      fq[field_name] ||= []
      fq[field_name] << field_value

      link = "#{request.path_info}?q=#{CGI.escape(params['q'])}"
      fq.each_pair do |field, vals|
        link += "&#{field}=#{CGI.escape(vals.join(';'))}"
      end
      link
    end

    def facet?(field_name)
      abstract_facet_query.key?(field_name)
    end

    def search_link(opts)
      fields = Sinatra::Application.settings.facet_fields + %w(q sort) # 'filter' ??
      parts = fields.map do |field|
        if opts.key? field.to_sym
          "#{field}=#{CGI.escape(opts[field.to_sym])}"
        elsif params.key? field
          params[field].split(';').map do |_field_value|
            "#{field}=#{CGI.escape(params[field])}"
          end
        end
      end

      "#{request.path_info}?#{parts.compact.flatten.join('&')}"
    end

    def search_results(solr_result, _oauth = nil)
      found_dois = solr_result.fetch('response', {}).fetch('docs', []).map { |solr_doc| solr_doc['doi'] }
      events = get_events(found_dois)

      # check whether dois have been claimed by user
      # handle search without logged in user, and handle errors
      claims = current_user.present? ? get_claims(current_user, found_dois) : []

      solr_result.fetch('response', {}).fetch('docs', []).map do |solr_doc|
        doi = solr_doc['doi']
        puts claims
        claim_status = claims.find { |c| c["doi"] == doi } || { "status" => "none" }
        claim_status = claim_status["status"]

        signposts = events.fetch(doi, [{}]).first.fetch(:signposts, {})

        SearchResult.new(solr_doc, solr_result, claim_status, signposts)
      end
    end
  end
end
