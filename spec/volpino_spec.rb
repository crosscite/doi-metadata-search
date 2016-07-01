require 'spec_helper'

describe "Volpino", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:auth_hash) { OmniAuth.config.mock_auth[:jwt] }
  let(:user) { User.new(auth_hash) }

  subject { ApiSearch.new }

  context "get_claims" do
    # it "with works" do
    #   works = subject.get_works(q: "martin fenner")
    #   works_with_claims = subject.get_claims(user, works[:data])
    #   work = works_with_claims[7]
    #   expect(work).to eq("id"=>"http://doi.org/10.5281/ZENODO.34673",
    #                      "type"=>"works",
    #                      "attributes"=>{"author"=>[{"family"=>"Fenner", "given"=>"Martin"}],
    #                                     "title"=>"DataCite/ORCID Integration",
    #                                     "container-title"=>"Zenodo",
    #                                     "description"=>"<p>DataCite Profiles and ORCID Auto-Update webinar.</p>",
    #                                     "published"=>"2015",
    #                                     "issued"=>"2015-12-03T17:06:41Z",
    #                                     "doi"=>"10.5281/ZENODO.34673",
    #                                     "resource-type-general"=>"Text",
    #                                     "resource-type"=>"Presentation",
    #                                     "type"=>"report",
    #                                     "license"=>"info:eu-repo/semantics/openAccess",
    #                                     "publisher-id"=>"CERN.ZENODO",
    #                                     "claim-status"=>"done"})
    # end

    it "no works" do
      works = []
      works_with_claims = subject.get_claims(user, [])
      expect(works_with_claims).to eq(works)
    end

    it "no current_user" do
      works = []
      works_with_claims = subject.get_claims(nil, [])
      expect(works_with_claims).to eq(works)
    end
  end
end
