# -*- coding: utf-8 -*-

require_relative 'doi'
require_relative 'session'
require_relative 'paginate'
require 'log4r'


helpers do
  include Doi
  include Session
  include Log4r
  #ap logger

  def logger
    Log4r::Logger['test']    
  end

  def partial template, locals
    haml template.to_sym, :layout => false, :locals => locals
  end

  def citations doi
    citations = settings.citations.find({'to.id' => doi})

    citations.map do |citation|
      hsh = {
        :id => citation['from']['id'],
        :authority => citation['from']['authority'],
        :type => citation['from']['type'],
      }

      if citation['from']['authority'] == 'cambia'
        patent = settings.patents.find_one({:patent_key => citation['from']['id']})
        hsh[:url] = "http://lens.org/lens/patent/#{patent['pub_key']}"
        hsh[:title] = patent['title']
      end

      hsh
    end
  end

  def select query_params
    logger.debug "building query to send to #{settings.solr_url}#{settings.solr_select}, with params:\n" + query_params.ai
    page = query_page
    rows = query_rows
    results = settings.solr.paginate page, rows, settings.solr_select, :params => query_params
  end

  def response_format
    if params.has_key?('format') && params['format'] == 'json'
      'json'
    else
      'html'
    end
  end

  def query_page
    if params.has_key? 'page'
      params['page'].to_i
    else
      1
    end
  end

  def query_rows
    if params.has_key? 'rows'
      params['rows'].to_i
    else
      settings.default_rows
    end
  end

  def query_columns
    ['doi','creator','title','publisher','publicationYear','relatedIdentifier','alternateIdentifier','resourceTypeGeneral','resourceType','nameIdentifier','rights','version', 'score']
  end

  def query_terms
    query_info = query_type
    case query_info[:type]
    when :doi
      "doi:\"#{query_info[:value]}\""
    when :short_doi
      "doi:\"#{query_info[:value]}\""
    when :issn
      "issn:\"#{query_info[:value]}\""
    when :orcid
      "nameIdentifier:ORCID\:#{query_info[:value]}"
    else
      scrub_query(params['q'], false)
    end
  end

  def query_type
    if doi? params['q']
      {:type => :doi, :value => to_doi(params['q']).downcase}
    elsif short_doi?(params['q']) || very_short_doi?(params['q'])
      {:type => :short_doi, :value => to_long_doi(params['q'])}
    elsif issn? params['q']
      {:type => :issn, :value => params['q'].strip.upcase}
    elsif orcid? params['q']
      {:type => :orcid, :value => params['q'].strip}
    else
      {:type => :normal}
    end
  end

  def abstract_facet_query
    fq = {}
    settings.facet_fields.each do |field|
      if params.has_key? field
        params[field].split(';').each do |val|
          fq[field] ||= []
          fq[field] << val
        end
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

  def sort_term
    if 'publicationYear' == params['sort']
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
      :fl => query_columns,
      :rows => query_rows,
      :facet => settings.facet ? 'true' : 'false',
      'facet.field' => settings.facet_fields, 
      'facet.mincount' => 1,
      :hl => settings.highlighting ? 'true' : 'false',
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

  def facet_link_not field_name, field_value
    fq = abstract_facet_query
    fq[field_name].delete field_value
    fq.delete(field_name) if fq[field_name].empty?

    link = "#{request.path_info}?q=#{CGI.escape(params['q'])}"
    fq.each_pair do |field, vals|
      link += "&#{field}=#{CGI.escape(vals.join(';'))}"
    end
    link
  end

  def facet_link field_name, field_value
    fq = abstract_facet_query
    fq[field_name] ||= []
    fq[field_name] << field_value

    link = "#{request.path_info}?q=#{CGI.escape(params['q'])}"
    fq.each_pair do |field, vals|
      link += "&#{field}=#{CGI.escape(vals.join(';'))}"
    end
    link
  end

  def facet? field_name
    abstract_facet_query.has_key? field_name
  end

  def search_link opts
    fields = settings.facet_fields + ['q', 'sort']
    parts = fields.map do |field|
      if opts.has_key? field.to_sym
        "#{field}=#{CGI.escape(opts[field.to_sym])}"
      elsif params.has_key? field
        params[field].split(';').map do |field_value|
          "#{field}=#{CGI.escape(params[field])}"
        end
      end
    end

    "#{request.path_info}?#{parts.compact.flatten.join('&')}"
  end

  def authors_text contributors
    authors = contributors.map do |c|
      "#{c['given_name']} #{c['surname']}"
    end
    authors.join ', '
  end

  def search_results solr_result, oauth = nil
    claimed_dois = []
    profile_dois = []

    if signed_in?
      orcid_record = MongoData.coll('orcids').find_one({:orcid => sign_in_id})
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
        :in_profile => in_profile,
        :claimed => claimed
      }
      logger.debug "Adding solr_doc doi:#{doi} as new search results item"
      SearchResult.new solr_doc, solr_result, citations(solr_doc['doi']), user_state
    end
  end

  def scrub_query query_str, remove_short_operators
    query_str = query_str.gsub(/[\"\.\[\]\(\)\-:;\/%]/, ' ')
    query_str = query_str.gsub(/[\+\!\-]/, ' ') if remove_short_operators
    query_str = query_str.gsub(/AND/, ' ')
    query_str = query_str.gsub(/OR/, ' ')
    query_str.gsub(/NOT/, ' ')
  end

  def index_stats
    count_result = settings.solr.get settings.solr_select, :params => {
      :q => '*:*',
      :fq => 'has_metadata:true',
      :rows => 0
    }
    dataset_result = settings.solr.get settings.solr_select, :params => {
      :q => 'resourceTypeGeneral:Dataset',
      :rows => 0
    }
    text_result = settings.solr.get settings.solr_select, :params => {
      :q => 'resourceTypeGeneral:Text',
      :rows => 0
    }    
    software_result = settings.solr.get settings.solr_select, :params => {
      :q => 'resourceTypeGeneral:Software',
      :rows => 0
    }
    oldest_result = settings.solr.get settings.solr_select, :params => {
      :q => 'publicationYear:[1 TO *]',
      :rows => 1,
      :sort => 'publicationYear asc'
    }

    stats = []

    stats << {
      :value => count_result['response']['numFound'],
      :name => 'Total number of indexed DOIs',
      :number => true
    }

    stats << {
      :value => dataset_result['response']['numFound'],
      :name => 'Number of indexed datasets',
      :number => true
    }

    stats << {
      :value => text_result['response']['numFound'],
      :name => 'Number of indexed text documents',
      :number => true
    }
    
    stats << {
      :value => software_result['response']['numFound'],
      :name => 'Number of indexed software',
      :number => true
    }

    stats << {
      :value => oldest_result['response']['docs'].first['publicationYear'],
      :name => 'Oldest indexed publication year'
    }

    stats << {
      :value => MongoData.coll('orcids').count({:query => {:updated => true}}),
      :name => 'Number of ORCID profiles updated'
    }

    stats
  end

end

