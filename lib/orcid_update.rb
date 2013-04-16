# -*- coding: utf-8 -*-
require 'nokogiri'
require 'oauth2'
require 'log4r'

require_relative 'data'

class OrcidUpdate

  @queue = :orcid

  def initialize oauth
    @oauth = oauth
  end

  def self.perform oauth
    OrcidUpdate.new(oauth).perform
  end
  
  def logger
    Log4r::Logger['test']    
  end

  def perform
    oauth_expired = false

    begin

      # Need to check both since @oauth may or may not have been serialized back and forth from JSON.
      uid = @oauth[:uid] || @oauth['uid']
      
      logger.info "Updating user #{uid}"

      opts = {:site => settings.orcid[:site]}
      client = OAuth2::Client.new(settings.orcid[:client_id], settings.orcid[:client_secret], opts)
      token = OAuth2::AccessToken.new(client, @oauth['credentials']['token'])
      headers = {'Accept' => 'application/json'}
      response = token.get "/#{uid}/orcid-works", {:headers => headers}

      if response.status == 200
        puts response.body
        response_json = JSON.parse(response.body)
        parsed_dois = parse_dois(response_json)
        query = {:orcid => uid}
        orcid_record = settings.orcids.find_one(query)

        if orcid_record
          orcid_record['dois'] = parsed_dois
          settings.orcids.save(orcid_record)
        else
          doc = {:orcid => uid, :dois => parsed_dois, :locked_dois => []}
          settings.orcids.insert(doc)
        end
      else
        oauth_expired = true
      end
    rescue StandardError => e
      logger.debug "An error occured: #{e}"
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

  def parse_dois json
    if !has_path?(json, ['orcid-profile', 'orcid-activities'])
      []
    else
      works = json['orcid-profile']['orcid-activities']['orcid-works']['orcid-work']

      extracted_dois = works.map do |work_loc|
        doi = nil
        if has_path?(work_loc, ['work-external-identifiers', 'work-external-identifier'])
          ids_loc = work_loc['work-external-identifiers']['work-external-identifier']

          ids_loc.each do |id_loc|
            id_type = id_loc['work-external-identifier-type']
            id_val = id_loc['work-external-identifier-id']['value']

            if id_type.upcase == 'DOI'
              doi = id_val
            end
          end

        end
        doi
      end

      extracted_dois.compact
    end
  end
end

