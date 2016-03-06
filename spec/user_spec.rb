require 'spec_helper'

describe User, vcr: true do
  let(:auth_hash) { OmniAuth.config.mock_auth[:jwt] }

  subject { User.new(auth_hash) }

  it "authentication_token" do
    expect(subject.authentication_token).to eq("MZEsj3SaSZkfpeKSXmT1")
  end
end
