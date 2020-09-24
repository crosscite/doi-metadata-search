require 'spec_helper'

describe "SessionHelper", vcr: true do
  let(:cookie) { User.generate_cookie(role_id: "staff_admin") }
  let(:user) { User.new(cookie) }

  subject { user }

  it "is_person" do
    expect(subject.is_person?).to be true
  end

  it "is_admin_or_staff" do
    expect(subject.is_admin_or_staff?).to be true
  end

  it "has_orcid_token" do
    expect(subject.has_orcid_token).to be false
  end
end
