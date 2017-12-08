require 'spec_helper'

describe User, vcr: true do
  let(:jwt) { User.generate_token(role_id: "staff_admin") }
  let(:user) { User.new(jwt) }

  subject { user }

  context "user" do
    it "has orcid" do
      expect(subject.orcid).to eq("0000-0001-5489-3594")
    end

    it "has name" do
      expect(user.name).to eq("Josiah Carberry")
    end

    it "has role" do
      expect(subject.role_id).to eq("staff_admin")
    end
  end
end
