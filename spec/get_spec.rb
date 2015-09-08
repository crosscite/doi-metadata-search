require 'spec_helper'

describe 'get' do

  it '/' do
    get '/'
    expect(last_response).to be_ok
  end
end
