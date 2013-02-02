# -*- coding: utf-8 -*-
require 'nokogiri'
require 'oauth2'

require_relative 'data'

class OrcidClaim

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

    begin
      puts to_xml

      # Need to check both since @oauth may or may not have been serialized back and forth from JSON.
      uid = @oauth[:uid] || @oauth['uid']

      opts = {:site => settings.orcid[:site]}
      client = OAuth2::Client.new(settings.orcid[:client_id], settings.orcid[:client_secret], opts)
      token = OAuth2::AccessToken.new(client, @oauth['credentials']['token'])
      headers = {'Accept' => 'application/json'}
      response = token.post("https://api.orcid.org/#{uid}/orcid-works") do |post|
        post.headers['Content-Type'] = 'application/orcid+xml'
        post.body = to_xml
      end
      oauth_expired = !response.success?
    rescue StandardError => e
      puts e
    end

    !oauth_expired
  end

  def has_path? hsh, path
    loc = hsh
    path.each do |path_item|
      if loc[path_item]
        loc = loc[path_item]
      else
        loc = nil
        break
      end
    end
    loc != nil
  end

  def orcid_work_type internal_work_type
    case internal_work_type
    when 'journal_article' then 'journal-article'
    when 'conference_paper' then 'conference-proceedings'
    else ''
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

  def insert_id xml, type, value
    xml.send(:'work-external-identifier') {
      xml.send(:'work-external-identifier-type', type)
      xml.send(:'work-external-identifier-id', value)
    }
  end

  def insert_ids xml
     xml.send(:'work-external-identifiers') {
      insert_id(xml, 'doi', @work['doi'])
      insert_id(xml, 'isbn', @work['proceedings']['isbn']) if has_path?(@work, ['proceedings', 'isbn'])
      insert_id(xml, 'issn', @work['journal']['issn']) if has_path?(@work, ['journal', 'issn'])
    }
  end

  def insert_pub_date xml
    month_str = pad_date_item(@work['published']['month'])
    day_str = pad_date_item(@work['published']['day'])
    if @work['published']
      xml.send(:'publication-date') {
        xml.year(@work['published']['year'].to_i.to_s)
        xml.month(month_str) if month_str
        xml.day(day_str) if day_str
      }
    end
  end

  def insert_type xml
    xml.send(:'work-type', orcid_work_type(@work['type']))
  end

  def insert_titles xml
    subtitle = case @work['type']
               when 'journal_article'
                 if has_path?(@work, ['journal', 'full_title'])
                   @work['journal']['full_title']
                 else
                   nil
                 end
               when 'conference_paper'
                 if has_path?(@work, ['proceedings', 'title'])
                   @work['proceedings']['title']
                 else
                   nil
                 end
               else
                 nil
               end

    if subtitle || @work['title']
      xml.send(:'work-title') {
        xml.title(@work['title']) if @work['title']
        xml.subtitle(subtitle) if subtitle
      }
    end
  end

  def insert_contributors xml
    if @work['contributors'] && !@work['contributors'].count.zero?
      xml.send(:'work-contributors') {
        @work['contributors'].each do |contributor|
          full_name = ""
          full_name = contributor['given_name'] if contributor['given_name']
          full_name += " " + contributor['surname'] if contributor['surname']
          if !full_name.empty?
            xml.contributor {
              xml.send(:'credit-name', full_name)
              # TODO Insert contributor roles and sequence once available
              # in 'dois' mongo collection.
              #xml.send(:'contributor-attributes') {
              #  xml.send(:'contributor-role', 'author')
              #}
            }
          end
        end
      }
    end
  end

  def insert_citation xml
    conn = Faraday.new
    response = conn.get "http://data.crossref.org/#{@work['doi']}", {}, {
      'Accept' => 'application/x-bibtex'
    }

    if response.status == 200
      xml.send(:'work-citation') {
        xml.send(:'work-citation-type', 'bibtex')
        xml.citation {
          xml.cdata(response.body)
        }
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
end
