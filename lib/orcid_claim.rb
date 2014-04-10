# -*- coding: utf-8 -*-
require 'nokogiri'
require 'oauth2'
require 'open-uri'

require_relative 'data'
require_relative 'doi'

class OrcidClaim
  include Doi

  @queue = :orcid

  ORCID_VERSION = '1.1'

  def initialize oauth, work
    @oauth = oauth
    @work = work
  end

  def self.perform oauth, work
    OrcidClaim.new(oauth, work).perform
  end

  def perform
    oauth_expired = false

    begin
      load_config

      # Need to check both since @oauth may or may not have been serialized back and forth from JSON.
      uid = @oauth[:uid] || @oauth['uid']

      #$stderr.puts to_xml

      opts = {:site => @conf['orcid_site']}
      client = OAuth2::Client.new(@conf['orcid_client_id'], @conf['orcid_client_secret'], opts)
      token = OAuth2::AccessToken.new(client, @oauth['credentials']['token'])
      headers = {'Accept' => 'application/json'}
      response = token.post("#{@conf['orcid_site']}/v#{ORCID_VERSION}/#{uid}/orcid-works") do |post|
        post.headers['Content-Type'] = 'application/orcid+xml'
        post.body = to_xml
      end
      #$stderr.puts response
      oauth_expired = response.status >= 400
    rescue StandardError => e
      oauth_expired = true
      #$stderr.puts e
    end

    !oauth_expired
  end

  def orcid_work_type internal_work_type
    case internal_work_type
    when 'Journal Article' then 'journal-article'
    when 'Conference Paper' then 'conference-paper'
    when 'Dissertation' then 'dissertation'
    when 'Report' then 'report'
    when 'Standard' then 'standards-and-policy'
    when 'Dataset' then 'data-set'
    when 'Book' then 'book'
    when 'Reference' then 'book'
    when 'Monograph' then 'book'
    else 'other'
    end
  end

  def pad_date_item item
    result = nil
    if item
      begin
        item_int = item.to_s.strip.to_i
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
    if @work['hl_subtitle'] && !@work['hl_subtitle'].empty?
      subtitle = @work['hl_subtitle'].first
    end

    if subtitle || @work['hl_title']
      xml.send(:'work-title') {
        if @work['hl_title'] && !@work['hl_title'].empty?
          xml.title(without_control(@work['hl_title'].first))
        end
        if subtitle
          xml.subtitle(without_control(subtitle))
        end
      }
    end

    container_title = nil
    if @work['hl_publication'] && !@work['hl_publication'].empty?
      container_title = @work['hl_publication'].last
    end

    if container_title
      xml.send(:'journal-title', container_title)
    end
  end

  def insert_contributors xml
    xml.send(:'work-contributors') {
      ['author', 'editor'].each do |t|
        if !@work["hl_#{t}s"].nil?
          @work["hl_#{t}s"].split(',').each do |c|
            xml.contributor {
              xml.send(:'credit-name', c.strip())
              xml.send(:'contributor-attributes') {
                xml.send(:'contributor-role', t)
              }
            }
          end
        end
      end
    }
  end

  def insert_citation xml
    conn = Faraday.new
    response = conn.get "http://data.crossref.org/#{URI.encode(to_doi(@work['doi_key']))}", {}, {
      'Accept' => 'application/x-bibtex'
    }

    if response.status == 200
      xml.send(:'work-citation') {
        xml.send(:'work-citation-type', 'bibtex')
        xml.citation(without_control(response.body))
      }
    end
  end

  def without_control s
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
      :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.1.xsd',
      :'xmlns' => 'http://www.orcid.org/ns/orcid'
    }

    Nokogiri::XML::Builder.new do |xml|
      xml.send(:'orcid-message', root_attributes) {
        xml.send(:'message-version', ORCID_VERSION)
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
