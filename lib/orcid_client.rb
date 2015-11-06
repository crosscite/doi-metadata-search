require 'oauth2'

class OrcidClient
  attr_reader :uid, :token, :client, :access_token, :get, :post

  def initialize(session_info)
    if ENV['JWT_URL'].present?
      token = session_info.fetch('info', {}).fetch('authentication_token', nil)
    else
      token = session_info.fetch('credentials', {}).fetch('token', nil)
    end
    client = OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                                ENV['ORCID_CLIENT_SECRET'],
                                site: ENV['ORCID_API_URL'])
    @access_token = OAuth2::AccessToken.new(client, token)
    @uid = session_info.fetch('uid', nil)
  end

  def get
    access_token.get "#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{uid}/orcid-works" do |get|
      get.headers['Accept'] = 'application/json'
    end
  end

  def post(data)
    access_token.post("#{ENV['ORCID_API_URL']}/v#{ORCID_VERSION}/#{uid}/orcid-works") do |post|
      post.headers['Content-Type'] = 'application/orcid+xml'
      post.body = data
    end
  end
end
