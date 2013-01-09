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

  def self.perform oauth, work
    OrcidClaim.new(ouath, work).perform
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
    started

    begin
      client = OAuth2::Client.new(@oauth[:client_id], @oauth[:client_secret], {:site => @oauth[:site]})
      token = OAuth2::AccessToken.new(client, @oauth[:token])

      response = token.post("https://api.orcid.org/#{@oauth[:uid]}/orcid-works") do |post|
        post.headers['Content-Type'] = 'application/orcid+xml'
        post.body = to_xml
      end

      if response.status == 200
        finished
      else
        failed(response.status)
      end
    rescue StandardError => e
      failed(e)
    end
  end

  def to_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.orcid-message {
        xml.message-version('1.0.7')
        xml.orcid-profile {
          xml.orcid-activities {
            xml.orcid-works {
              xml.orcid-work {
                xml.work-title {
                  xml.title(@work[:title])
                }
                xml.work-type(@work[:type])
                xml.publication-date {
                  xml.year(@work[:year])
                  xml.month(@work[:month]) if @work[:month]
                  xml.day(@work[:day]) if @work[:day]
                }
                xml.work-external-identifiers {
                  xml.work-external-identifier {
                    xml.work-external-identifier-type('doi')
                    xml.work-external-identifier-id(@work[:doi])
                  }
                }
                xml.url("http://dx.doi.org/#{@work[:doi]}")
                xml.work-contributors {
                  @work[:contributors].each do |contributor|
                    xml.contributor {
                      xml.credit-name(contributor.full_name)
                      xml.contributor-attributes {
                        xml.contributor-role('author')
                      }
                    }
                  end
                }
              }
            }
          }
        }
      }
    end.to_s
  end

end
