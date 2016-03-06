require 'spec_helper'

describe 'orcid', vcr: true do
  let(:auth_hash) { OmniAuth.config.mock_auth[:jwt] }
  let(:user) { User.new(auth_hash) }
  let(:params) {{ "orcid" => "0000-0002-1825-0097", "doi" => "10.5061/DRYAD.781PV" }}
  let(:headers) {{ "HTTP_AUTHORIZATION" => "Token token=#{user.authentication_token}" }}

  it 'claim' do
    get '/orcid/claim', params, headers
    expect(JSON.parse(last_response.body)).to eq("status"=>"ok")
  end

  it 'unclaim' do
    get '/orcid/unclaim', params, headers
    expect(JSON.parse(last_response.body)).to eq("status"=>"ok")
  end
end
