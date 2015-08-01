require 'spec_helper'

describe "orcid" do
  it "activity" do
    get '/orcid/activity'
    expect(last_response.status).to eq(302)
  end

  it "claim" do
    get '/orcid/claim'
    expect(last_response).to be_ok
  end

  it "unclaim" do
    get '/orcid/unclaim'
    expect(last_response).to be_ok
  end

  it "sync" do
    get '/orcid/sync'
    expect(last_response).to be_ok
  end
end
