require 'sinatra/base'
require 'json'

require_relative 'doi'
require_relative 'session'
require_relative 'paginate'

module Sinatra
  module Search
    include Sinatra::Doi
    include Sinatra::Session

    def select(query_params)
      page = query_page
      rows = query_rows
      results = settings.solr.paginate(page, rows, ENV['SOLR_SELECT'], params: query_params)
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

    def query_columns
      %w(doi creator title publisher publicationYear relatedIdentifier alternateIdentifier resourceTypeGeneral resourceType nameIdentifier rightsURI version description descriptionType score)
    end

    def query_fields
      "doi creator title^2 publisher publicationYear relatedIdentifier alternateIdentifier resourceTypeGeneral resourceType nameIdentifier subject rightsURI version description descriptionType score"
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

    def query_type
      if doi? params['q']
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
      params['q'] != '*' ? params['q'] : ''
    end

    def facet_query_fields
      settings.facet_fields.select { |field| params.key?(field) }
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
      fq = ['has_metadata:true', 'NOT relatedIdentifier:IsPartOf\:*']
      abstract_facet_query.each_pair do |name, values|
        values.each do |value|
          fq << "#{name}: \"#{value}\""
        end
      end
      fq
    end

    def facet_results(solr_result)
      return {} if solr_result['facet_counts'].nil?

      results = solr_result.fetch('facet_counts', {}).fetch('facet_fields', [])
      # results.reduce({}) do |sum, facet|
      #   if facet.last.size > 0
      #     sum << facet
      #   else
      #     sum
      #   end
      # end
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
      abstract_facet_query.key? field_name
    end

    def search_link(opts)
      fields = settings.facet_fields + %w(q sort) # 'filter' ??
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
      claimed_dois = []
      profile_dois = []

      if signed_in?
        orcid_record = settings.orcids.find_one(orcid: sign_in_id)
        unless orcid_record.nil?
          claimed_dois = orcid_record['dois'] + orcid_record['locked_dois'] if orcid_record
          profile_dois = orcid_record['dois']
        end
      end

      solr_result['response']['docs'].map do |solr_doc|
        doi = solr_doc['doi']
        in_profile = profile_dois.include?(doi)
        claimed = claimed_dois.include?(doi)
        user_state = {
          in_profile: in_profile,
          claimed: claimed
        }
        SearchResult.new(solr_doc, solr_result, citations(solr_doc['doi']), user_state)
      end
    end

    def scrub_query(query_str, remove_short_operators)
      query_str = query_str.gsub(/[\"\.\[\]\(\)\-:;\/%]/, ' ')
      query_str = query_str.gsub(/[\+\!\-]/, ' ') if remove_short_operators
      query_str = query_str.gsub(/AND/, ' ')
      query_str = query_str.gsub(/OR/, ' ')
      query_str.gsub(/NOT/, ' ')
    end

    def get_alt_text(page)
      if page[:query_type][:type] == :doi
        query = "/works/#{page[:query_type][:value]}"
      else
        query = "?query=#{page[:bare_query]}&rows=0"
      end

      conn = Faraday.new(url: 'http://api.crossref.org') do |c|
        c.response :encoding
        c.adapter Faraday.default_adapter
      end

      res = conn.get do |req|
        req.url query
      end
      response = ActiveSupport::JSON.decode(res.body)

      if res.status == 200 && page[:query_type][:type] == :doi
        response.fetch('message', {}).length > 0 ? 'DOI found' : 'DOI not found'
      elsif res.status == 200
        response.fetch('message', {}).fetch('total-results', 0).to_s + ' results'
      else
        '0 results'
      end
    rescue ::JSON::ParserError
      'DOI not found'
    end
  end
end
