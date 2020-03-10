require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resourceTypes"].first).to eq("count"=>679314, "id"=>"text", "title"=>"Text")
      work = response[:data].first
      expect(work["id"]).to eq("10.0143/ipk/gbis/test/1")
    end

    it "one" do
      response = subject.get_works(id: "10.70001/12334296")
      work = response[:data]
      expect(work.dig("attributes", "creators").first).to eq("affiliation"=>[], "name"=>"Joyce Mott Anderson")
      expect(response[:included].size).to eq(1)
      client = response[:included][0]
      expect(client.dig("attributes", "clientType")).to eq("periodical")
    end

    it "one not found" do
      response = subject.get_works(id: "10.4226/xxxx")
      work = response[:data]
      expect(work).to be_empty
    end

    it "related_identifiers" do
      response = subject.get_works("work-id" => "10.5438/0004")
      #expect(response[:meta]["resource-types"].first).to eq("id"=>"text", "title"=>"Text", "count"=>3)
      work = response[:data].first
      expect(work["id"]).to eq("10.0143/ipk/gbis/test/1")
    end

    it "query" do
      response = subject.get_works(query: "california")
      expect(response[:meta]["resourceTypes"].first).to eq("count"=>2189, "id"=>"text", "title"=>"Text")
      work = response[:data].first
      expect(work["id"]).to eq("10.21977/zmhc-mz86")
    end
  end

  context "get_people" do
    it "all" do
      response = subject.get_people
      expect(response[:meta]).to eq("total"=>66357, "totalPages"=>400, "page"=>1)
      contributor = response[:data].first
      expect(contributor["id"]).to eq("0000-0001-9354-2586")
    end

    it "one" do
      response = subject.get_people(id: "0000-0002-2220-6072")
      contributor = response[:data]
      expect(contributor).to eq("attributes" => {"created"=>"2017-12-15T16:50:05.000Z", "familyName"=>"'t Sas-Rolfes", "github"=>nil, "givenNames"=>"Michael", "isActive"=>false, "name"=>"Michael 't Sas-Rolfes", "orcid"=>"https://orcid.org/0000-0002-2220-6072", "roleId"=>"user", "updated"=>"2017-12-15T16:50:05.000Z"},
        "id" => "0000-0002-2220-6072",
        "relationships" => {},
        "type" => "users")
    end

    it "query" do
      response = subject.get_people(query: "garza")
      expect(response[:meta]).to eq("total"=>6, "totalPages"=>1, "page"=>1)
      contributor = response[:data][1]
      expect(contributor).to eq("attributes" => {"created"=>"2016-08-01T16:25:38.000Z", "familyName"=>"Garza", "github"=>"https://github.com/kjgarza", "givenNames"=>"Kristian", "isActive"=>false, "name"=>"K. J. Garza", "orcid"=>"https://orcid.org/0000-0003-3484-6876", "roleId"=>"staff_admin", "updated"=>"2018-05-30T05:00:34.000Z"},
        "id" => "0000-0003-3484-6876",
        "relationships" => {},
        "type" => "users")
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      datacenter = response[:data].first
      expect(datacenter["attributes"]["name"]).to eq("027.7 - Zeitschrift für Bibliothekskultur")
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenter = response[:data]
      expect(datacenter["id"]).to eq("cern.zenodo")
    end

    it "query" do
      response = subject.get_datacenters(query: "zenodo")
      expect(response[:meta]["providers"].first).to eq("id"=>"cern", "title"=>"CERN - European Organization for Nuclear Research", "count"=>1)
      datacenter = response[:data].first
      expect(datacenter["id"]).to eq("cern.zenodo")
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]["regions"].first).to eq("id"=>"amer", "title"=>"Americas", "count"=>118)
      member = response[:data].first
      expect(member["id"]).to eq("akristia")
    end

    it "one" do
      response = subject.get_members(id: "ANDS")
      member = response[:data]
      expect(member["id"]).to eq("ands")
    end

    it "query" do
      response = subject.get_members(query: "ands")
      expect(response[:meta]["regions"].first).to eq("id"=>"apac", "title"=>"Asia and Pacific", "count"=>1)
      member = response[:data].first
      expect(member["id"]).to eq("ands")
    end
  end
end
