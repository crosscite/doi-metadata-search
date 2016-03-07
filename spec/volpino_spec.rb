require 'spec_helper'

describe "Volpino", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:auth_hash) { OmniAuth.config.mock_auth[:jwt] }
  let(:user) { User.new(auth_hash) }
  let(:solr_doc) { { "doi" => "10.5061/dryad.f1cb2" } }
  let(:solr_result) { ::ActiveSupport::JSON.decode(File.read(fixture_path + 'solr_response.json')) }
  let(:claimed) { false }
  let(:related_identifiers) { {} }

  let(:doi) { "10.6084/M9.FIGSHARE.681735" }
  let(:dois) { ["10.5281/ZENODO.30030","10.6084/M9.FIGSHARE.681735"] }

  subject { SearchResult.new(solr_doc, solr_result, claimed, related_identifiers) }

  context "get_claims" do
    it "get single doi" do
      response = subject.get_claims(user, [doi])
      expect(response.length).to eq(1)
      expect(response.first).to eq("doi"=>"10.6084/M9.FIGSHARE.681735", "status"=>"done")
    end

    it "get multiple dois" do
      response = subject.get_claims(user, dois)
      expect(response.length).to eq(2)
      expect(response.first).to eq("doi"=>"10.6084/M9.FIGSHARE.681735", "status"=>"done")
    end

    it "get multiple dois with errors" do
      url = "#{ENV['JWT_HOST']}/api/users/#{user.orcid}/claims?dois=#{dois.join(",")}"
      stub = stub_request(:get, url).to_return(:status => [408])
      response = subject.get_claims(user, dois)
      expect(response).to be_empty
    end

    it "get no doi" do
      response = subject.get_claims(user, [])
      expect(response).to be_empty
    end
  end
end
