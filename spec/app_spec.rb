require 'spec_helper'

describe "Sinatra App" do

  it "should respond to get" do
    get '/'
    last_response.should be_ok
  end
  
  context "help" do  
    it "should get help for api" do
      get '/help/api'
      last_response.should be_ok
    end
  
    it "should get help for search" do
      get '/help/search'
      last_response.should be_ok
    end
  
    it "should get status" do
      get '/help/status'
      last_response.should be_ok
    end
  end
  
  context "api" do
    it "should get dois" do
      get '/dois'
      last_response.should be_ok
    end
  end
end