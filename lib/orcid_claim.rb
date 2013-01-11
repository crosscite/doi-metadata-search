# -*- coding: utf-8 -*-
require 'nokogiri'
require 'oauth2'

require_relative 'data'

class OrcidClaim

  @queue = :orcid

  def initialize oauth, work, record_id
    @oauth = oauth
    @work = work
    @record_id = record_id
  end

  def self.perform oauth, work, record_id
    OrcidClaim.new(oauth, work, record_id).perform
  end

  def self.prepare orcid, doi
    doc = {:created_at => Time.now, :orcid => orcid, :doi => doi}
    MongoData.coll('claims').insert(doc)
  end

  def started
    MongoData.coll('claims').update(@record_id, {:started_at => Time.now})
  end

  def failed e = nil
    MongoData.coll('claims').update(@record_id, {:failed_at => Time.now, :error => e})
  end

  def finished
    MongoData.coll('claims').update(@record_id, {:finished_at => Time.now})
  end

  def perform
    begin
      started
      load_config

      # Need to check both since @oauth may or may not have been serialized back and forth from JSON.
      uid = @oauth[:uid] || @oauth['uid']

      opts = {:site => @conf['orcid_site']}
      client = OAuth2::Client.new(@conf['orcid_client_id'], @conf['orcid_client_secret'], opts)
      token = OAuth2::AccessToken.new(client, @oauth['credentials']['token'])
      headers = {'Accept' => 'application/json'}
      response = token.post("https://api.orcid.org/#{uid}/orcid-works") do |post|
        post.headers['Content-Type'] = 'application/orcid+xml'
        post.body = to_xml
      end

      if response.status == 200
        finished
      else
        failed(response.status)
      end
    rescue StandardError => e
      puts e
    end
  end

  def orcid_work_type internal_work_type
    case internal_work_type
    when 'journal_article' then 'journal-article'
    when 'conference_paper' then 'conference-proceedings'
    else ''
    end
  end

  def pad_date_item item
    item_str = item.to_s.strip
    if item_str.length < 2
      "0" + item_str
    else
      item_str
    end
  end

  def to_xml
    root_attributes = {
      :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid http://orcid.github.com/ORCID-Parent/schemas/orcid-message/1.0.7/orcid-message-1.0.7.xsd',
      :'xmlns' => 'http://www.orcid.org/ns/orcid'
    }

    Nokogiri::XML::Builder.new do |xml|
      xml.send(:'orcid-message', root_attributes) {
        xml.send(:'message-version', '1.0.7')
        xml.send(:'orcid-profile') {
          xml.send(:'orcid-activities') {
            xml.send(:'orcid-works') {
              xml.send(:'orcid-work') {
                xml.send(:'work-title') {
                  xml.title(@work['title'])
                }
                xml.send(:'work-type', orcid_work_type(@work['type']))
                if @work['published']
                  xml.send(:'publication-date') {
                    xml.year(@work['published']['year'].to_i.to_s)
                    xml.month(pad_date_item(@work['published']['month'])) if @work['published']['month']
                    xml.day(pad_date_item(@work['published']['day'])) if @work['published']['day']
                  }
                end
                xml.send(:'work-external-identifiers') {
                  xml.send(:'work-external-identifier') {
                    xml.send(:'work-external-identifier-type', 'doi')
                    xml.send(:'work-external-identifier-id', @work['doi'])
                  }
                }
                xml.send(:'work-contributors') {
                  @work['contributors'].each do |contributor|
                    full_name = ""
                    full_name = contributor['given_name'] if contributor['given_name']
                    full_name += " " + contributor['surname'] if contributor['surname']
                    if !full_name.empty?
                      xml.contributor {
                        xml.send(:'credit-name', full_name)
                        # TODO ORCID is complaining about contribuor-role in attribs
                        #xml.send(:'contributor-attributes') {
                        #  xml.send(:'contributor-role', 'author')
                        #}
                      }
                    end
                  end
                }
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
