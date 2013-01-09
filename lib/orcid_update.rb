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
      client = OAuth2::Client.new(@oauth[:client_id], @oauth[:client_secret], {:site => @oauth[:site]})
      token = OAuth2::AccessToken.new(client, @oauth[:token])

      response = token.get("/#{@oauth[:uid]}/orcid-works") do |get|
        get.headers['Accept'] = 'application/orcid+xml'
      end

      if response.status == 200
        work_xml = response.body
        parsed_dois = parse_dois work_xml
        orcid_record = MongoData.coll('orcids').find_one({:orcid => @oauth[:uid]})

        if orcid_record
          dois_to_insert = parsed_dois - orcid_record['dois']
          orcid_record['dois'] = orcid_record['dois'] + dois_to_insert
          MongoData.coll['orcids'].save orcid_record
        else
          new_record = {:orcid => @oauth[:uid], :dois => parsed_dois}
          MongoData.coll['orcids'].insert new_record
        end
      end
    end
  end

  def parse_dois work_xml
    doc = Nokogiri::XML.parse(work_xml)
    identifiers = doc.css('work-external-identifier')
    dois = identifiers.map do |identifier_loc|
      if identifier.at_css('work-external-identifier-type').text == 'doi'
        identifier_loc.at_css('work-external-identifier-id').text
      end
    end
    dois.compact
  end

end

