require 'spec_helper'

describe "oauth" do
  it "callback" do
    get '/auth/orcid/callback'
    expect(last_response).to be_ok
  end

  it "failure" do
    get '/auth/orcid/failure'
    expect(last_response.status).to eq(404)
  end

  it "signout" do
    get '/auth/signout'
    expect(last_response.status).to eq(302)
  end

  it "deauthorized" do
    get '/auth/orcid/deauthorized'
    expect(last_response).to be_ok
  end
end
