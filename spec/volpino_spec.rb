require 'spec_helper'

describe "Volpino", type: :model, vcr: true do
  let(:cookie) { User.generate_cookie(role_id: "staff_admin") }
  let(:user) { User.new(cookie) }

  subject { ApiSearch.new }

  context "found_dois" do
    it "with works" do
      works = subject.get_works(query: "martin fenner")[:data]
      expect(subject.found_dois(works).length).to eq(7)
    end
  
    it "without works" do
      works = []
      expect(subject.found_dois(works)).to be_blank
    end
  end
  
  context "get_claims" do
    it "without works" do
      dois = ["10.5060/3a79-xq77"]
      claims = subject.get_claims(user, dois)
      expect(claims[:data].length).to eq(0)
    end
  end
  
  context "merge_claims" do
    it "with works" do
      works = subject.get_works(query: "martin fenner")[:data]
      dois = subject.found_dois(works)
      claims = subject.get_claims(user, dois)[:data]
      merged_claims = subject.merge_claims(works, claims)
      statuses = merged_claims.map { |mc| mc["attributes"]["claim-status"] }
      expect(works.length).to eq(7)
      expect(statuses.length).to eq(7)
      expect(statuses.inject(Hash.new(0)) { |total, e| total[e] += 1 ; total }).to eq("none"=>7)
    end
  end
  
  context "get_claimed_items" do
    it "with works" do
      works = subject.get_works(query: "martin fenner")[:data]
      works_with_claims = subject.get_claimed_items(user, works)
      expect(works.length).to eq(7)
      expect(works_with_claims.length).to eq(7)
      work = works_with_claims[3]
      expect(work["id"]).to eq("10.5438/mk65-3m12")
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
