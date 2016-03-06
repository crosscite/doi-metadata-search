require 'spec_helper'

describe 'auth', vcr: true do
  it 'callback' do
    get '/auth/jwt/callback'
    expect(last_response.status).to eq(302)
  end

  it 'failure' do
    get '/auth/orcid/failure'
    expect(last_response.status).to eq(404)
  end

  it 'signout' do
    get '/auth/signout'
    expect(last_response.status).to eq(302)
  end
end
