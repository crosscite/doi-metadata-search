require_relative 'doi'
require_relative 'session'
require_relative 'paginate'
require 'log4r'

helpers do
  include Doi
  include Session
  include Log4r
  # ap logger

  def logger
    Log4r::Logger['test']
  end

  def capture_exception(e, env)
    if ENV['SENTRY_DSN']
      evt = Raven::Event.capture_rack_exception(e, env)
      Raven.send(evt) if evt
    end
  end

  def partial(template, locals)
    haml template.to_sym, layout: false, locals: locals
  end

  def citations(doi)
    citations = settings.citations.find('to.id' => doi)

    citations.map do |citation|
      hsh = {
        id: citation['from']['id'],
        authority: citation['from']['authority'],
        type: citation['from']['type']
      }

      if citation['from']['authority'] == 'cambia'
        patent = settings.patents.find_one(patent_key: citation['from']['id'])
        hsh[:url] = "http://lens.org/lens/patent/#{patent['pub_key']}"
        hsh[:title] = patent['title']
      end

      hsh
    end
  end

  def select(query_params)
    logger.debug "building query to send to #{ENV['SOLR_URL']}#{ENV['SOLR_SELECT']}, with params:\n" + query_params.ai
    page = query_page
    rows = query_rows
    results = settings.solr.paginate page, rows, ENV['SOLR_SELECT'], params: query_params
  end

  def response_format
    if params.key?('format') && params['format'] == 'json'
      'json'
    else
      'html'
    end
  end

  def query_page
    if params.key? 'page'
      params['page'].to_i
    else
      1
    end
  end

  def query_rows
    if params.key? 'rows'
      params['rows'].to_i
    else
      DEFAULT_ROWS
    end
  end

  def query_columns
    %w(doi creator title publisher publicationYear relatedIdentifier alternateIdentifier resourceTypeGeneral resourceType nameIdentifier subject rights version description descriptionType score)
  end

  def query_terms
    query_info = query_type
    case query_info[:type]
    when :doi
      "doi:\"#{query_info[:value]}\""
    when :short_doi
      "doi:\"#{query_info[:value]}\""
    when :orcid
      orcid = query_info[:value][0]
      names = Array(query_info[:value][1..-1]).uniq
      orcid_terms(orcid, names)
    when :contributpr
      "creator:#{query_info[:value]} OR contributor:#{query_info[:value]}"
    when :year
      "publicationYear:\"#{query_info[:value]}\""
    when :publisher
      "publisher:#{query_info[:value]} OR datacentre:#{query_info[:value]}"
    when :type
      "resourceType:#{query_info[:value]} OR resourceTypeGeneral:#{query_info[:value]}"
    when :subject
      "subject:#{query_info[:value]}"
    when :rights
      "rights:#{query_info[:value]}"
    when :urn
      "alternateIdentifier:#{query_info[:value]}"
    when :issn
      "*:#{query_info[:value]}"
    else
      scrub_query(params['q'], false)
    end
  end

  def orcid_terms(orcid, names)
    name_identifier = ["nameIdentifier:ORCID\:#{orcid}"]
    creators = names.map { |name| "creator:\"#{name.strip}\"~4" }
    contributors = names.map { |name| "contributor:\"#{name.strip}\"~4" }

    (name_identifier + creators + contributors).join(' OR ')
  end

  def query_type
    if doi? params['q']
      { type: :doi, value: to_doi(params['q']).downcase }
    elsif short_doi?(params['q']) || very_short_doi?(params['q'])
      { type: :short_doi, value: to_long_doi(params['q']) }
    elsif value = orcid?(params['q'])
      { type: :orcid, value: value }
    elsif value = contributor?(params['q'])
      { type: :contributor, value: value }
    elsif value = year?(params['q'])
      { type: :year, value: value }
    elsif value = publisher?(params['q'])
      { type: :publisher, value: value }
    elsif value = type?(params['q'])
      { type: :type, value: value }
    elsif value = subject?(params['q'])
      { type: :subject, value: value }
    elsif value = rights?(params['q'])
      { type: :rights, value: value }
    elsif issn? params['q']
      { type: :issn, value: params['q'].strip.upcase }
    elsif urn? params['q']
      { type: :urn, value: params['q'].strip }
    else
      { type: :normal }
    end
  end

  def abstract_facet_query
    fq = {}
    settings.facet_fields.each do |field|
      if params.key? field
        params[field].split(';').each do |val|
          fq[field] ||= []
          fq[field] << val
        end
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
      :facet => FACET ? 'true' : 'false',
      'facet.field' => settings.facet_fields,
      'facet.mincount' => 1,
      :hl => HIGHLIGHTING ? 'true' : 'false',
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

  def authors_text(contributors)
    authors = contributors.map do |c|
      "#{c['given_name']} #{c['surname']}"
    end
    authors.join ', '
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
      SearchResult.new solr_doc, solr_result, citations(solr_doc['doi']), user_state
    end
  end

  def scrub_query(query_str, remove_short_operators)
    query_str = query_str.gsub(/[\"\.\[\]\(\)\-:;\/%]/, ' ')
    query_str = query_str.gsub(/[\+\!\-]/, ' ') if remove_short_operators
    query_str = query_str.gsub(/AND/, ' ')
    query_str = query_str.gsub(/OR/, ' ')
    query_str.gsub(/NOT/, ' ')
  end

  def index_stats
    count_result = settings.solr.get ENV['SOLR_SELECT'], params: {
      q: '*:*',
      fq: 'has_metadata:true',
      rows: 0
    }
    dataset_result = settings.solr.get ENV['SOLR_SELECT'], params: {
      q: 'resourceTypeGeneral:Dataset',
      rows: 0
    }
    text_result = settings.solr.get ENV['SOLR_SELECT'], params: {
      q: 'resourceTypeGeneral:Text',
      rows: 0
    }
    software_result = settings.solr.get ENV['SOLR_SELECT'], params: {
      q: 'resourceTypeGeneral:Software',
      rows: 0
    }
    oldest_result = settings.solr.get ENV['SOLR_SELECT'], params: {
      q: 'publicationYear:[1 TO *]',
      rows: 1,
      sort: 'publicationYear asc'
    }

    stats = []

    stats << {
      value: count_result['response']['numFound'],
      name: 'Total number of indexed DOIs',
      number: true
    }

    stats << {
      value: dataset_result['response']['numFound'],
      name: 'Number of indexed datasets',
      number: true
    }

    stats << {
      value: text_result['response']['numFound'],
      name: 'Number of indexed text documents',
      number: true
    }

    stats << {
      value: software_result['response']['numFound'],
      name: 'Number of indexed software',
      number: true
    }

    stats << {
      value: oldest_result['response']['docs'].first['publicationYear'],
      name: 'Oldest indexed publication year'
    }

    stats << {
      value: MongoData.coll('orcids').count(query: { updated: true }),
      name: 'Number of ORCID profiles updated'
    }

    stats
  end

  def get_alt_count(page)
    if page[:query_type][:type] == :doi
      query = "/#{page[:query_type][:value]}"
    else
      query = "?query=#{page[:bare_query]}&rows=0"
    end

    conn = Faraday.new(url: 'http://api.crossref.org/works') do |c|
      c.response :encoding
      c.adapter Faraday.default_adapter
    end

    response = conn.get do |req|
      req.url query
      req.headers['Accept'] = citation_format
    end

    if response.status == 200 && page[:query_type][:type] == :doi
      JSON.parse(response.body).fetch('message', {}).length > 0 ? 'DOI found' : 'DOI not found'
    elsif response.status == 200
      JSON.parse(response.body).fetch('message', {}).fetch('total-results', 0).to_s + ' results'
    else
      '0 results'
    end
  rescue JSON::ParserError
    'DOI not found'
  end

  def force_utf8(str)
    str.strip.force_encoding('UTF-8')
  end
end
