require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resource-types"].first).to eq("id"=>"text", "title"=>"Text", "count"=>59573)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.0312/DQ6M-DG3X")
    end

    it "one" do
      response = subject.get_works(id: "10.4124/CCDC.CSD.CC1JJR93")
      work = response[:data]
      expect(work["attributes"]["author"].first).to eq("family"=>"Koumousi", "given"=>"Evangelia S.")
      expect(response[:included].size).to eq(3)
      resource_type = response[:included][2]
      expect(resource_type).to eq("id"=>"dataset", "type"=>"resource-types", "attributes"=>{"title"=>"Dataset", "updated"=>"2016-09-21T00:00:00Z"})
    end

    it "one not found" do
      response = subject.get_works(id: "10.4226/xxxx")
      work = response[:data]
      expect(work).to be_empty
    end

    it "related_identifiers" do
      response = subject.get_works("work-id" => "10.5438/0004")
      expect(response[:meta]["resource-types"].first).to eq("id"=>"text", "title"=>"Text", "count"=>3)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.5438/0006")
    end

    it "query" do
      response = subject.get_works(query: "woodruff")
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>109)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.6067/XCV85Q4V4C")
    end
  end

  context "get_people" do
    it "all" do
      response = subject.get_people
      expect(response[:meta]).to eq("total"=>21305)
      contributor = response[:data].first
      expect(contributor["id"]).to eq("http://orcid.org/0000-0002-6909-1823")
    end

    it "one" do
      response = subject.get_people(id: "0000-0003-3484-6875")
      contributor = response[:data]
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0003-3484-6875", "type"=>"people", "attributes" => {"given"=>"Kristian", "family"=>"Garza", "literal"=>"K. J. Garza", "orcid"=>"http://orcid.org/0000-0003-3484-6875", "github"=>"https://github.com/kjgarza", "updated"=>"2016-09-07T13:24:13.000Z"})
    end

    it "query" do
      response = subject.get_people(query: "garza")
      expect(response[:meta]).to eq("total"=>4)
      contributor = response[:data][1]
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0002-5493-877X", "type"=>"people", "attributes" => {"given"=>"Jose Arturo", "family"=>"Garza-Reyes", "literal"=>"Jose Arturo Garza-Reyes", "orcid"=>"http://orcid.org/0000-0002-5493-877X", "github"=>nil, "updated"=>"2016-10-14T11:38:01.000Z"})
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      datacenter = response[:data].first
      expect(datacenter["attributes"]["title"]).to eq("(TIB-intern) Grafische Einzelbl\u00E4tter der Sammlung Haupt (GESAH)")
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenter = response[:data]
      expect(datacenter["id"]).to eq("cern.zenodo")
    end

    it "query" do
      response = subject.get_datacenters(query: "zeno")
      expect(response[:meta]["members"].first).to eq("id"=>"cern", "title"=>"CERN - European Organization for Nuclear Research", "count"=>1)
      datacenter = response[:data].first
      expect(datacenter["id"]).to eq("cern.zenodo")
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]["member-types"].first).to eq("id"=>"allocating", "title"=>"Allocating", "count"=>31)
      member = response[:data].first
      expect(member["id"]).to eq("ands")
    end

    it "one" do
      response = subject.get_members(id: "ANDS")
      member = response[:data]
      expect(member["id"]).to eq("ands")
    end

    it "query" do
      response = subject.get_members(query: "tib")
      expect(response[:meta]["member-types"].first).to eq("id"=>"allocating", "title"=>"Allocating", "count"=>1)
      member = response[:data].first
      expect(member["id"]).to eq("tib")
    end
  end
end
