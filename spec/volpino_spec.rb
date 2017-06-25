require 'spec_helper'

describe "Volpino", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:jwt) { ENV['JWT_EXAMPLE'] }
  let(:user) { User.new(jwt) }

  subject { ApiSearch.new }

  context "found_dois" do
    it "with works" do
      works = subject.get_works(query: "martin fenner")[:data]
      expect(subject.found_dois(works).length).to eq(25)
    end

    it "without works" do
      works = []
      expect(subject.found_dois(works)).to be_blank
    end
  end

  context "get_claims" do
    it "with works" do
      dois = ["10.5438/53NZ-N4G7", "10.5438/G59A-FBT2"]
      claims = subject.get_claims(user, dois)
      expect(claims[:data].length).to eq(2)
      expect(claims[:data].first["attributes"]["orcid"]).to eq("0000-0001-6528-2027")
    end
  end

  context "merge_claims" do
    it "with works" do
      works = subject.get_works(query: "martin fenner")[:data]
      dois = subject.found_dois(works)
      claims = subject.get_claims(user, dois)[:data]
      merged_claims = subject.merge_claims(works, claims)
      statuses = merged_claims.map { |mc| mc["attributes"]["claim-status"] }
      expect(works.length).to eq(25)
      expect(statuses.length).to eq(25)
      expect(statuses.inject(Hash.new(0)) { |total, e| total[e] += 1 ; total }).to eq("done"=>4, "none"=>21)
    end
  end

  context "get_claimed_items" do
    it "with works" do
      works = subject.get_works(query: "martin fenner")[:data]
      works_with_claims = subject.get_claimed_items(user, works)
      expect(works.length).to eq(25)
      expect(works_with_claims.length).to eq(25)
      work = works_with_claims[3]
      expect(work["id"]).to eq("https://doi.org/10.5438/9SNZ-VV1Y")
      expect(work["attributes"]["claim-status"]).to eq("none")
    end

    it "no works" do
      works = []
      works_with_claims = subject.get_claimed_items(user, [])
      expect(works_with_claims).to eq(works)
    end

    it "no current_user" do
      works = subject.get_works(query: "martin fenner")[:data]
      works_with_claims = subject.get_claimed_items(nil, works)
      expect(works_with_claims).to eq(works)
    end
  end
end
