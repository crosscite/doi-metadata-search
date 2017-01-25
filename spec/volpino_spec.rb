require 'spec_helper'

describe "Volpino", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:jwt) { [{"uid"=>"0000-0003-1419-2405", "api_key"=>ENV['ORCID_UPDATE_KEY'], "name"=>"Martin Fenner", "email"=>nil, "role"=>"user", "iat"=>1472762438}, {"typ"=>"JWT", "alg"=>"HS256"}] }
  let(:user) { User.new(jwt.first) }

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
      dois = ["10.6084/M9.FIGSHARE.706340.V1", "10.5281/ZENODO.34673"]
      claims = subject.get_claims(user, dois)
      expect(claims[:data].length).to eq(0)
      # expect(claims[:data].first["attributes"]["orcid"]).to eq("0000-0003-1419-2405")
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
      expect(statuses.inject(Hash.new(0)) { |total, e| total[e] += 1 ; total }).to eq("none"=>25)
    end

    it "with relations" do
      relations = subject.get_relations("work-id" => "10.5281/ZENODO.48705")
      relations= Array(relations.fetch(:data, [])).select {|item| item["type"] == "relations" }
      dois = subject.found_dois(relations)
      claims = subject.get_claims(user, dois)[:data]
      merged_claims = subject.merge_claims(relations, claims)
      statuses = merged_claims.map { |mc| mc["attributes"]["claim-status"] }
      expect(relations.length).to eq(0)
      # expect(statuses.length).to eq(3)
      # expect(statuses.inject(Hash.new(0)) { |total, e| total[e] += 1 ;total}).to eq("none"=>2, "done"=>1)
    end

    it "with contributions" do
      contributions = subject.get_contributions("contributor-id" => "orcid.org/#{user.orcid}", rows: 100)
      contributions= Array(contributions.fetch(:data, [])).select {|item| item["type"] == "contributions" }
      dois = subject.found_dois(contributions)
      claims = subject.get_claims(user, dois)[:data]
      merged_claims = subject.merge_claims(contributions, claims)
      statuses = merged_claims.map { |mc| mc["attributes"]["claim-status"] }
      expect(contributions.length).to eq(60)
      expect(statuses.length).to eq(60)
      expect(statuses.inject(Hash.new(0)) { |total, e| total[e] += 1 ;total}).to eq("none"=>60)
    end
  end

  context "get_claimed_items" do
    it "with works" do
      works = subject.get_works(query: "martin fenner")[:data]
      works_with_claims = subject.get_claimed_items(user, works)
      expect(works.length).to eq(25)
      expect(works_with_claims.length).to eq(25)
      work = works_with_claims[3]
      expect(work["id"]).to eq("https://doi.org/10.6084/M9.FIGSHARE.706340.V1")
      expect(work["attributes"]["claim-status"]).to eq("none")
    end

    it "with relations" do
      relations = subject.get_relations("work-id" => "10.5281/ZENODO.48705")
      relations= Array(relations.fetch(:data, [])).select {|item| item["type"] == "relations" }
      relations_with_claims = subject.get_claimed_items(user, relations)
      expect(relations.length).to eq(0)
      # expect(relations_with_claims.length).to eq(3)
      # relation = relations_with_claims[2]
      # expect(relation["attributes"]["doi"]).to eq("10.5281/ZENODO.30799")
      # expect(relation["attributes"]["claim-status"]).to eq("done")
    end

    it "with contributions" do
      contributions = subject.get_contributions("contributor-id" => "orcid.org/#{user.orcid}", rows: 100)
      contributions= Array(contributions.fetch(:data, [])).select {|item| item["type"] == "contributions" }
      contributions_with_claims = subject.get_claimed_items(user, contributions)
      expect(contributions.length).to eq(60)
      expect(contributions_with_claims.length).to eq(60)
      contribution = contributions_with_claims[0]
      expect(contribution["attributes"]["doi"]).to eq("10.6084/M9.FIGSHARE.1048991.V2")
      expect(contribution["attributes"]["claim-status"]).to eq("none")
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
