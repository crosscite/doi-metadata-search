require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>5738)
      work = response[:data].first
      expect(work["id"]).to eq("https://handle.test.datacite.org/10.4124/73nbydxz48.1")
    end

    it "one" do
      response = subject.get_works(id: "10.21956/mniopenres.14275.r26250")
      work = response[:data]
      expect(work["attributes"]["author"].first).to eq("literal"=>"A A")
      expect(response[:included].size).to eq(3)
      resource_type = response[:included][1]
      expect(resource_type).to eq("id"=>"text", "type"=>"resource-types", "attributes"=>{"title"=>"Text", "updated"=>"2016-09-21T00:00:00Z"}, "relationships"=>{})
    end

    it "one not found" do
      response = subject.get_works(id: "10.4226/xxxx")
      work = response[:data]
      expect(work).to be_empty
    end

    # it "related_identifiers" do
    #   response = subject.get_works("work-id" => "10.5438/0004")
    #   #expect(response[:meta]["resource-types"].first).to eq("id"=>"text", "title"=>"Text", "count"=>3)
    #   work = response[:data].first
    #   expect(work["id"]).to eq("https://doi.org/10.5438/0006")
    # end

    it "query" do
      response = subject.get_works(query: "california")
      #expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>109)
      work = response[:data].first
      expect(work["id"]).to eq("https://handle.test.datacite.org/10.22002/d1.505")
    end
  end

  context "get_people" do
    it "all" do
      response = subject.get_people
      expect(response[:meta]).to eq("total"=>21327, "total-pages"=>854, "page"=>1)
      contributor = response[:data].first
      expect(contributor["id"]).to eq("https://orcid.org/0000-0002-6909-1823")
    end

    it "one" do
      response = subject.get_people(id: "0000-0001-6528-2027")
      contributor = response[:data]
      expect(contributor).to eq("id"=>"https://orcid.org/0000-0001-6528-2027", "type"=>"people", "attributes"=>{"given"=>"Martin", "family"=>"Fenner", "literal"=>"Martin Fenner", "orcid"=>"https://orcid.org/0000-0001-6528-2027", "github"=>"mfenner", "updated"=>"2018-01-03T16:18:11.000Z"})
    end

    it "query" do
      response = subject.get_people(query: "garza")
      expect(response[:meta]).to eq("total"=>4, "total-pages"=>1, "page"=>1)
      contributor = response[:data][1]
      expect(contributor).to eq("id"=>"https://orcid.org/0000-0002-5493-877X", "type"=>"people", "attributes" => {"given"=>"Jose Arturo", "family"=>"Garza-Reyes", "literal"=>"Jose Arturo Garza-Reyes", "orcid"=>"https://orcid.org/0000-0002-5493-877X", "github"=>nil, "updated"=>"2016-10-14T11:38:01.000Z"})
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      datacenter = response[:data].first
      expect(datacenter["attributes"]["title"]).to eq("027.7 - Zeitschrift für Bibliothekskultur")
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenter = response[:data]
      expect(datacenter["id"]).to eq("cern.zenodo")
    end

    it "query" do
      response = subject.get_datacenters(query: "zeno")
      #expect(response[:meta]["members"].first).to eq("id"=>"cern", "title"=>"CERN - European Organization for Nuclear Research", "count"=>1)
      datacenter = response[:data].first
      expect(datacenter["id"]).to eq("cern.zenodo")
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]["regions"].first).to eq("id"=>"amer", "title"=>"Americas", "count"=>1)
      member = response[:data].first
      expect(member["id"]).to eq("nansa")
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
