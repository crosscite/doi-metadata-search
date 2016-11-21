require 'spec_helper'

describe User, vcr: true do
  let(:jwt) { [{"uid"=>"0000-0003-1419-2405", "api_key"=>ENV['ORCID_UPDATE_KEY'], "name"=>"Martin Fenner", "email"=>nil, "role"=>"user", "iat"=>1472762438}, {"typ"=>"JWT", "alg"=>"HS256"}] }
  let(:user) { User.new(jwt.first) }

  subject { user }

  context "user" do
    it "has orcid" do
      expect(subject.orcid).to eq("0000-0003-1419-2405")
    end

    it "has api_key" do
      expect(user.api_key).not_to be nil
    end

    it "has role" do
      expect(subject.role).to eq("user")
    end
  end
end
