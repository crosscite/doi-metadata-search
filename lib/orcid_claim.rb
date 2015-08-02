require 'nokogiri'
require 'oauth2'
require 'log4r'
require 'open-uri'

require_relative 'data'
require_relative 'doi'

class OrcidClaim
  # Map of DataCite work types to the CASRAI-based ORCID type vocabulary
  TYPE_OF_WORK = {

    'Audiovisual' => 'other',
    'Collection' => 'other',
    'Dataset' =>  'data-set',
    'Event' => 'other',
    'Image' => 'other',
    'InteractiveResource' => 'online-resource',
    'Model' => 'other',
    'PhysicalObject' => 'other',
    'Service' => 'other',
    'Software' => 'other',
    'Sound' => 'other',
    'Text' => 'other',
    'Workflow' => 'other',
    'Other' => 'other',

    # Legacy types from older schema versions
    'Film' => 'other'
    # pick up other legacy types as we go along
  }

  # Map of DataCite work types to ORCID original BibTeX-based type vocabulary. Derived from
  # DataCite metadata schema v3 (current as of Nov 2013)

  TYPE_OF_WORK_DISABLED = {
    'Audiovisual' => 'audiovisual',
    'Collection' => 'other',
    'Dataset' =>  'other',
    'Event' => 'other',
    'Image' => 'digital-image',
    'InteractiveResource' => 'other',
    'Model' => 'other',
    'PhysicalObject' => 'other',
    'Service' => 'other',
    'Software' => 'software',
    'Sound' => 'other',
    'Text' => 'other',
    'Workflow' => 'other',
    'Other' => 'other',

    # Legacy types from older schema versions
    'Film' => 'film-movie'
  }

  include Doi

  @queue = :orcid

  def initialize(oauth, work)
    @oauth = oauth
    @work = work
  end

  def self.perform(oauth, work)
    OrcidClaim.new(oauth, work).perform
  end

  def perform
    oauth_expired = false

    begin
      # Need to check both since @oauth may or may not have been serialized back and forth from JSON.
      uid = @oauth[:uid] || @oauth['uid']

      # $stderr.puts to_xml

      opts = { site: ENV['ORCID_API_URL'] }
      client = OAuth2::Client.new(ENV['ORCID_CLIENT_ID'], ENV['ORCID_CLIENT_SECRET'], opts)
      token = OAuth2::AccessToken.new(client, @oauth['credentials']['token'])
      headers = { 'Accept' => 'application/json' }
      response = token.post("#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{uid}/orcid-works") do |post|
        post.headers['Content-Type'] = 'application/orcid+xml'
        post.body = to_xml
      end
      # $stderr.puts response
      oauth_expired = response.status >= 400
    rescue StandardError => e
      oauth_expired = true
      # $stderr.puts e
    end

    !oauth_expired
  end

  # Heuristic for determing the type of the work based on A) the general, high-level label
  # from the `resourceTypeGeneral field` (controlled list) and B)) the value of the  more specific
  # `resourceType` field which is not from a controlled list but rather free-form input from data centres.
  def orcid_work_type(internal_work_type, internal_work_subtype)
    logger.debug "Determining ORCID work type term from  #{internal_work_type} / #{internal_work_subtype}"
    type =  case  internal_work_type
            when 'Text'
              case internal_work_subtype
              when /^(Article|Articles|Journal Article|JournalArticle)$/i
                'journal-article'
              when /^(Book|ebook|Monografie|Monograph\w*|)$/i
                'book'
              when /^(chapter|chapters)$/i
                'book-chapter'
              when /^(Project report|Report|Research report|Technical Report|TechnicalReport|Text\/Report|XFEL.EU Annual Report|XFEL.EU Technical Report)$/i
                'report'
              when /^(Dissertation|thesis|Doctoral thesis|Academic thesis|Master thesis|Masterthesis|Postdoctoral thesis)$/i
                'dissertation'
              when /^(Conference Abstract|Conference extended abstract)$/i
                'conference-abstract'
              when /^(Conference full text|Conference paper|ConferencePaper)$/i
                'conference-paper'
              when /^(poster|Conference poster)$/i
                'conference-poster'
              when /^(working paper|workingpaper|preprint)$/i
                'working-paper'
              when /^(dataset$)/i
                'data-set'
              end

            when 'Collection'
              case internal_work_subtype
              when /^(Collection of Datasets|Data Files|Dataset|Supplementary Collection of Datasets)$/i
                'data-set'
              when 'Report'
                'report'
              end
            end  # double CASE statement ends

    if type.nil?
      logger.info "Got nothing from heuristic, falling back on generic type mapping for '#{internal_work_type}' or else defaulting to other"
      type = TYPE_OF_WORK[internal_work_type] || 'other'
    end

    logger.debug "Final work type mapping: #{internal_work_type || 'undef'} / #{internal_work_subtype || 'undef'} => #{type || 'undef'}"
    type
  end

  def pad_date_item(item)
    result = nil
    if item
      begin
        item_int = item.to_s.strip.to_i
        if item_int >= 0 && item_int <= 11
          item_str = item_int.to_s
          if item_str.length < 2
            result = '0' + item_str
          elsif item_str.length == 2
            result = item_str
          end
        end
      rescue StandardError => e
        # Ignore type conversion errors
      end
    end
    result
  end

  def to_issn(uri)
    uri.strip.sub(/\Ahttp:\/\/id.crossref.org\/issn\//, '')
  end

  def to_isbn(uri)
    uri.strip.sub(/\Ahttp:\/\/id.crossref.org\/isbn\//, '')
  end

  def insert_id(xml, type, value)
    xml.send(:'work-external-identifier') do
      xml.send(:'work-external-identifier-type', type)
      xml.send(:'work-external-identifier-id', value)
    end
  end

  def insert_ids(xml)
    xml.send(:'work-external-identifiers') do
      insert_id(xml, 'doi', to_doi(@work['doi_key']))
      # Do not insert ISSNs and ISBNs as currently they are treated
      # as unique per work by ORCID
      # insert_id(xml, 'isbn', to_isbn(@work['isbn'].first)) if @work['isbn'] && !@work['isbn'].empty?
      # insert_id(xml, 'issn', to_issn(@work['issn'].first)) if @work['issn'] && !@work['issn'].empty?
    end
  end

  def insert_pub_date(xml)
    if @work['hl_year']
      month_str = pad_date_item(@work['month'])
      day_str = pad_date_item(@work['day'])

      xml.send(:'publication-date') do
        xml.year(@work['hl_year'].to_i.to_s)
        xml.month(month_str) if month_str
        xml.day(day_str) if month_str && day_str
      end
    end
  end

  def insert_type(xml)
    xml.send(:'work-type', orcid_work_type(@work['type'], @work['subtype']))
  end

  def insert_titles(xml)
    subtitle = nil
    if @work['hl_subtitle'] && !@work['hl_subtitle'].empty?
      subtitle = @work['hl_subtitle'].first
    end

    if subtitle || @work['hl_title']
      xml.send(:'work-title') do
        if @work['hl_title'] && !@work['hl_title'].empty?
          xml.title(without_control(@work['hl_title'].first))
        end
        if subtitle
          xml.subtitle(without_control(subtitle))
        end
      end
    end

    container_title = nil
    if @work['hl_publication'] && !@work['hl_publication'].empty?
      container_title = @work['hl_publication'].last
    end

    if container_title
      xml.send(:'journal-title', container_title)
    end
  end

  def insert_contributors(xml)
    if @work['contributors'] && !@work['contributors'].count.zero?
      xml.send(:'work-contributors') do
        @work['contributors'].each do |contributor|
          full_name = ''
          full_name = contributor['given_name'] if contributor['given_name']
          full_name += ' ' + contributor['surname'] if contributor['surname']
          unless full_name.empty?
            xml.contributor do
              xml.send(:'credit-name', full_name)
              # TODO Insert contributor roles and sequence once available
              # in 'dois' mongo collection.
              # xml.send(:'contributor-attributes') {
              #  xml.send(:'contributor-role', 'author')
              # }
            end
          end
        end
      end
    end
  end

  def insert_citation(xml)
    conn = Faraday.new(url: 'http://data.datacite.org') do |c|
      c.response :encoding
      c.adapter Faraday.default_adapter
    end

    response = conn.get "/#{URI.encode(to_doi(@work['doi_key']))}", {},
                        'Accept' => 'application/x-bibtex'

    if response.status == 200
      xml.send(:'work-citation') do
        xml.send(:'work-citation-type', 'bibtex')
        xml.citation(without_control(response.body))
      end
    end
  end

  def without_control(s)
    r = ''
    s.each_codepoint do |c|
      if c >= 32
        r << c
      end
    end
    r
  end

  def to_xml
    root_attributes = {
      :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.2.xsd',
      :'xmlns' => 'http://www.orcid.org/ns/orcid'
    }

    Nokogiri::XML::Builder.new do |xml|
      xml.send(:'orcid-message', root_attributes) do
        xml.send(:'message-version', ORCID_VERSION)
        xml.send(:'orcid-profile') do
          xml.send(:'orcid-activities') do
            xml.send(:'orcid-works') do
              xml.send(:'orcid-work') do
                insert_titles(xml)
                insert_citation(xml)
                insert_type(xml)
                insert_pub_date(xml)
                insert_ids(xml)
                insert_contributors(xml)
              end
            end
          end
        end
      end
    end.to_xml
  end
end
