# -*- coding: utf-8 -*-
require 'nokogiri'
require 'oauth2'

require_relative 'data'
require_relative 'doi'

class OrcidClaim
  include Doi

  @queue = :orcid

  def initialize oauth, work
    @oauth = oauth
    @work = work
  end

  def self.perform oauth, work
    OrcidClaim.new(oauth, work).perform
  end

  def perform
    oauth_expired = false

    log_file = File.open('log/orcid-claim.log', 'a')

    begin
      load_config

      log_file << to_xml

      # Need to check both since @oauth may or may not have been serialized back and forth from JSON.
      uid = @oauth[:uid] || @oauth['uid']

      opts = {:site => @conf['orcid_site']}
      client = OAuth2::Client.new(@conf['orcid_client_id'], @conf['orcid_client_secret'], opts)
      token = OAuth2::AccessToken.new(client, @oauth['credentials']['token'])
      headers = {'Accept' => 'application/json'}
      response = token.post("#{@conf['orcid_site']}/#{uid}/orcid-works") do |post|
        post.headers['Content-Type'] = 'application/orcid+xml'
        post.body = to_xml
      end
      oauth_expired = response.status >= 400
      
      log_file << response
    rescue StandardError => e
      oauth_expired = true
      log_file << e
    end

    log_file.close()

    !oauth_expired
  end

  def orcid_work_type internal_work_type
    case internal_work_type
    when 'Journal Article' then 'journal-article'
    when 'Conference Paper' then 'conference-proceedings'
    when 'Dissertation' then 'dissertation'
    when 'Report' then 'report'
    when 'Standard' then 'standards'
    when 'Dataset' then 'database'
    when 'Book' then 'book'
    when 'Reference' then 'book'
    when 'Monograph' then 'book'
    when 'Chapter' then 'components'
    when 'Section' then 'components'
    when 'Part' then 'components'
    when 'Track' then 'components'
    when 'Component' then 'components'
    when 'Entry' then 'components'
    else 'other'
    end
  end

  def pad_date_item item
    result = nil
    if item
      begin
        item_int = item.strip.to_i
        if item_int >= 0 && item_int <= 11
          item_str = item_int.to_s
          if item_str.length < 2
            result = "0" + item_str
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

  def to_issn uri
    uri.strip.sub(/\Ahttp:\/\/id.crossref.org\/issn\//, '')
  end

  def to_isbn uri
    uri.strip.sub(/\Ahttp:\/\/id.crossref.org\/isbn\//, '')
  end

  def insert_id xml, type, value
    xml.send(:'work-external-identifier') {
      xml.send(:'work-external-identifier-type', type)
      xml.send(:'work-external-identifier-id', value)
    }
  end

  def insert_ids xml
     xml.send(:'work-external-identifiers') {
      insert_id(xml, 'doi', to_doi(@work['doi_key']))
      insert_id(xml, 'isbn', to_isbn(@work['isbn'].first)) if @work['isbn'] && !@work['isbn'].empty?
      insert_id(xml, 'issn', to_issn(@work['issn'].first)) if @work['issn'] && !@work['issn'].empty?
    }
  end

  def insert_pub_date xml
    month_str = pad_date_item(@work['month'])
    day_str = pad_date_item(@work['day'])
    if @work['hl_year']
      xml.send(:'publication-date') {
        xml.year(@work['hl_year'].to_i.to_s)
        xml.month(month_str) if month_str
        xml.day(day_str) if day_str
      }
    end
  end

  def insert_type xml
    xml.send(:'work-type', orcid_work_type(@work['type']))
  end

  def insert_titles xml
    subtitle = nil
    if @work['hl_publication'] && !@work['hl_publication'].empty?
      subtitle = @work['hl_publication'].first
    end

    if subtitle || @work['hl_title']
      xml.send(:'work-title') {
        xml.title(@work['hl_title'].first) if @work['hl_title'] && !@work['hl_title'].empty?
        xml.subtitle(subtitle) if subtitle
      }
    end
  end

  def insert_contributors xml
    # TODO Insert contributor roles and sequence once available
    # in 'dois' mongo collection.
    # xml.send(:'contributor-attributes') {
    #   xml.send(:'contributor-role', 'author')
    # }
  end

  def insert_citation xml
    conn = Faraday.new
    response = conn.get "http://data.crossref.org/#{to_doi(@work['doi_key'])}", {}, {
      'Accept' => 'application/x-bibtex'
    }

    if response.status == 200
      xml.send(:'work-citation') {
        xml.send(:'work-citation-type', 'bibtex')
        xml.citation(response.body)
      }
    end
  end

  def to_xml
    root_attributes = {
      :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid http://orcid.github.com/ORCID-Parent/schemas/orcid-message/1.0.8/orcid-message-1.0.8.xsd',
      :'xmlns' => 'http://www.orcid.org/ns/orcid'
    }

    Nokogiri::XML::Builder.new do |xml|
      xml.send(:'orcid-message', root_attributes) {
        xml.send(:'message-version', '1.0.8')
        xml.send(:'orcid-profile') {
          xml.send(:'orcid-activities') {
            xml.send(:'orcid-works') {
              xml.send(:'orcid-work') {
                insert_titles(xml)
                insert_citation(xml)
                insert_type(xml)
                insert_pub_date(xml)
                insert_ids(xml)
                insert_contributors(xml)
              }
            }
          }
        }
      }
    end.to_xml
  end

  def load_config
    @conf ||= {}
    config = JSON.parse(File.open('conf/app.json').read)
    config.each_pair do |key, value|
      @conf[key] = value
    end
  end

end
