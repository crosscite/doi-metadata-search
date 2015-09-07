require 'sinatra/base'
require 'json'

module Sinatra
  module Search
    def query_columns
      %w(doi creator contributor contributorType title publisher publicationYear relatedIdentifier alternateIdentifier resourceTypeGeneral resourceType nameIdentifier rightsURI version description descriptionType xml score)
    end

    def query_fields
      "doi creator contributor contributorType title publisher publicationYear relatedIdentifier alternateIdentifier resourceTypeGeneral resourceType nameIdentifier subject rightsURI version description descriptionType"
    end

    def query_terms
      params['q'] = '*' if params['q'].blank?

      query_info = query_type
      case query_info[:type]
      when :doi
        "doi:\"#{query_info[:value]}\""
      when :short_doi
        "doi:\"#{query_info[:value]}\""
      when :orcid
        "nameIdentifier:ORCID\:#{query_info[:value]}"
      when :urn
        "alternateIdentifier:#{query_info[:value]}"
      when :issn
        "*:#{query_info[:value]}"
      else
        params['q']
      end
    end

    def sort_term
      if params.fetch('sort', nil) == 'publicationYear'
        'publicationYear desc, score desc'
      else
        'score desc'
      end
    end

    def search_query
      fq = facet_query
      query  = {
        :sort => sort_term,
        :q => query_terms,
        :qf => query_fields,
        :fl => query_columns,
        :rows => query_rows,
        :facet => 'true',
        'facet.field' => settings.facet_fields,
        'facet.limit' => 10,
        'f.resourceType_facet.facet.limit' => 15,
        'f.rightsURI.facet.prefix' => 'http://creativecommons.org',
        'f.format.facet.prefix' => 'application',
        'facet.mincount' => 1,
        :hl => 'true',
        'hl.fl' => 'hl_*',
        'hl.simple.pre' => '<span class="hl">',
        'hl.simple.post' => '</span>',
        'hl.mergeContinuous' => 'true',
        'hl.snippets' => 10,
        'hl.fragsize' => 0
      }

      query['fq'] = fq unless fq.empty?
      query
    end

    def get_alt_result(page)
      page[:alt_url] = "http://search.crossref.org/?q=#{page[:bare_query]}"

      if page[:query_type][:type] == :doi
        query = "/works/#{page[:query_type][:value]}"
      else
        query = "/works?query=#{page[:bare_query]}&rows=0"
      end

      conn = Faraday.new(url: 'http://api.crossref.org') do |c|
        c.response :encoding
        c.adapter Faraday.default_adapter
      end

      res = conn.get do |req|
        req.url query
      end
      response = ::ActiveSupport::JSON.decode(res.body)

      if res.status == 200 && page[:query_type][:type] == :doi
        page[:alt_text] = response.fetch('message', {}).length > 0 ? 'DOI found' : 'DOI not found'
      elsif res.status == 200
        page[:alt_text] = response.fetch('message', {}).fetch('total-results', 0).to_s + ' results'
      else
        page[:alt_text] = '0 results'
      end

      page[:alt_text] += " in the CrossRef Metadata Search."

      page
    rescue ::ActiveSupport::JSON.parse_error
      page[:alt_text] = page[:query_type][:type] == :doi ? 'DOI not found' : '0 results'
      page[:alt_text] += " in the CrossRef Metadata Search."

      page
    end
  end
end
