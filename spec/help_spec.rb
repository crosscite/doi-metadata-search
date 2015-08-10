require 'spec_helper'

describe 'help' do
  it 'search' do
    get '/help/examples'
    expect(last_response).to be_ok
  end

  it 'status' do
    get '/help/status'
    expect(last_response).to be_ok
  end
end
