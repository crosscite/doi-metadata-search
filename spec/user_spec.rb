require 'spec_helper'

describe User, vcr: true do
  let(:jwt) { ENV['JWT_EXAMPLE'] }
  let(:user) { User.new(jwt) }

  subject { user }

  context "user" do
    it "has orcid" do
      expect(subject.orcid).to eq("0000-0003-1419-2405")
    end

    it "has name" do
      expect(user.name).to eq("Martin Fenner")
    end

    it "has role" do
      expect(subject.role).to eq("admin")
    end
  end
end
