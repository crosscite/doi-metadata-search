require 'spec_helper'

describe "Sinatra App" do

  it "/" do
    get '/'
    expect(last_response).to be_ok
  end

  it "heartbeat" do
    get '/heartbeat'
    expect(last_response).to be_ok
  end

  context "help" do
    it "search" do
      get '/help/search'
      expect(last_response).to be_ok
    end

    it "status" do
      get '/help/status'
      expect(last_response).to be_ok
    end
  end
end
