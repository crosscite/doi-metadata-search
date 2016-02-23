require 'oauth2'

class OrcidClient
  attr_reader :orcid, :access_token, :client, :get, :post

  def initialize(current_user)
    client = OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                                ENV['ORCID_CLIENT_SECRET'],
                                site: ENV['ORCID_API_URL'])
    @access_token = OAuth2::AccessToken.new(client, current_user.authentication_token)
    @orcid = current_user.uid
  end

  def get
    access_token.get "#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{orcid}/orcid-works" do |get|
      get.headers['Accept'] = 'application/json'
    end
  end

  def post(data)
    access_token.post("#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{orcid}/orcid-works") do |post|
      post.headers['Content-Type'] = 'application/orcid+xml'
      post.body = data
    end
  end
end
