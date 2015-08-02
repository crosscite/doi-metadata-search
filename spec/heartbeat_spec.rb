require 'spec_helper'

describe 'heartbeat' do
  it 'heartbeat' do
    get '/heartbeat'
    expect(last_response).to be_ok
  end
end
