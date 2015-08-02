require 'spec_helper'

describe 'search' do

  it '/' do
    get '/'
    expect(last_response).to be_ok
  end
end
