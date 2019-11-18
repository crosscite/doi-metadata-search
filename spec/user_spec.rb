require 'spec_helper'

describe User, vcr: true do
  let(:cookie) { User.generate_cookie(role_id: "staff_admin") }
  let(:user) { User.new(cookie) }

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

    it "has role_name" do
      expect(subject.role_name).to eq("Staff")
    end
  end

  context 'generate_token' do
    it "default token" do
      token = User.generate_token
      expect(token).to be_present
    end
  end

  context 'decode_token' do
    let(:token) { User.generate_token }

    it "has name" do
      payload = subject.decode_token(token)
      expect(payload["name"]).to eq("Josiah Carberry")
    end

    it "empty token" do
      payload = subject.decode_token("")
      expect(payload).to eq(errors: "JWT::DecodeError: Not enough or too many segments for ")
    end

    it "invalid token" do
      payload = subject.decode_token("abc")
      expect(payload).to eq(errors: "JWT::DecodeError: Not enough or too many segments for abc")
    end

    it "expired token" do
      token = User.generate_token(exp: 0)
      payload = subject.decode_token(token)
      expect(payload[:errors]).to start_with("JWT::DecodeError: Signature has expired for")
    end
  end
end
