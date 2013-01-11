# -*- coding: utf-8 -*-
require 'nokogiri'
require 'oauth2'

require_relative 'data'

class OrcidUpdate

  @queue = :orcid

  def initialize oauth
    @oauth = oauth
  end

  def self.perform oauth
    OrcidUpdate.new(oauth).perform
  end

  def perform
    begin
      load_config

      # Need to check both since @oauth may or may not have been serialized back and forth from JSON.
      uid = @oauth[:uid] || @oauth['uid']

      opts = {:site => @conf['orcid_site']}
      client = OAuth2::Client.new(@conf['orcid_client_id'], @conf['orcid_client_secret'], opts)
      token = OAuth2::AccessToken.new(client, @oauth['credentials']['token'])
      headers = {'Accept' => 'application/json'}
      response = token.get "https://api.orcid.org/#{uid}/orcid-works", {:headers => headers}

      if response.status == 200
        response_json = JSON.parse(response.body)
        parsed_dois = parse_dois(response_json)
        query = {:orcid => uid}
        orcid_record = MongoData.coll('orcids').find_one(query)

        if orcid_record
          orcid_record['dois'] = parsed_dois
          MongoData.coll('orcids').save(orcid_record)
        else
          doc = {:orcid => uid, :dois => parsed_dois, :locked_dois => []}
          MongoData.coll('orcids').insert(doc)
        end
      end
    rescue StandardError => e
      puts e
    end
  end

  def parse_dois json
    p(json)

    works = json['orcid-profile']['orcid-activities']['orcid-works']['orcid-work']

    extracted_dois = works.map do |work_loc|
      ids_loc = work_loc['work-external-identifiers']['work-external-identifier']
      doi = nil

      ids_loc.each do |id_loc|
        id_type = id_loc['work-external-identifier-type']
        id_val = id_loc['work-external-identifier-id']['value']

        if id_type.upcase == 'DOI'
          doi = id_val
        end
      end

      doi
    end

    extracted_dois.compact
  end

  def load_config
    @conf ||= {}
    config = JSON.parse(File.open('conf/app.json').read)
    config.each_pair do |key, value|
      @conf[key] = value
    end
  end

end

