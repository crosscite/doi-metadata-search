require 'spec_helper'

describe 'orcid', vcr: true do
  let(:auth_hash) { OmniAuth.config.mock_auth[:jwt] }
  let(:user) { User.new(auth_hash) }
  let(:params) {{ "api_key" => user.api_key,
                  "orcid" => "0000-0002-1825-0097",
                  "doi" => "10.5061/DRYAD.781PV" }}

  it 'claim' do
    get '/orcid/claim', params
    expect(JSON.parse(last_response.body)).to eq("status"=>"waiting")
  end
end
