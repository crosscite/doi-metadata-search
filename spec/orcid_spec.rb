require 'spec_helper'

describe 'orcid', vcr: true do
  let(:jwt) { [{"uid"=>"0000-0003-1419-2405", "api_key"=>"S6sigjfa6Z5ao2c1sYxx", "name"=>"Martin Fenner", "email"=>nil, "role"=>"user", "iat"=>1472762438}, {"typ"=>"JWT", "alg"=>"HS256"}] }
  let(:user) { User.new(jwt.first) }
  let(:params) {{ "api_key" => user.api_key,
                  "orcid" => "0000-0002-1825-0097",
                  "doi" => "10.5061/DRYAD.781PV" }}

  it 'claim' do
    get '/orcid/claim', params
    expect(last_response.body).to eq(2)
  end
end
