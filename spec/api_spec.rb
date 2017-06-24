require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>3387093)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.13140/RG.2.2.28002.53448")
    end

    it "one" do
      response = subject.get_works(id: "10.2314/COSCV2.53")
      work = response[:data]
      expect(work["attributes"]["author"].first).to eq("family"=>"Pampel", "given"=>"Heinz", "orcid"=>"http://orcid.org/0000-0003-3334-2771")
      expect(response[:included].size).to eq(3)
      resource_type = response[:included][2]
      expect(resource_type).to eq("id"=>"text", "type"=>"resource-types", "attributes"=>{"title"=>"Text", "updated"=>"2016-09-21T00:00:00Z"})
    end

    it "related_identifiers" do
      response = subject.get_works("work-id" => "10.5061/DRYAD.Q447C")
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>3)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.5061/DRYAD.Q447C/3")
    end

    it "query" do
      response = subject.get_works(query: "mabbett")
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>15)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.6084/M9.FIGSHARE.5114329")
    end
  end

  context "get_people" do
    it "all" do
      response = subject.get_people
      expect(response[:meta]).to eq("total"=>32490)
      contributor = response[:data].first
      expect(contributor["id"]).to eq("http://orcid.org/0000-0002-7079-2475")
    end

    it "one" do
      response = subject.get_people(id: "0000-0003-3484-6875")
      contributor = response[:data]
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0003-3484-6875", "type"=>"people", "attributes"=>{"given"=>"Kristian", "family"=>"Garza", "literal"=>"K. J. Garza", "orcid"=>"http://orcid.org/0000-0003-3484-6875", "github"=>"https://github.com/kjgarza", "updated"=>"2017-06-12T13:40:13.000Z"})
    end

    it "query" do
      response = subject.get_people(query: "garza")
      expect(response[:meta]).to eq("total"=>7)
      contributor = response[:data][1]
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0003-3484-6875", "type"=>"people", "attributes"=>{"given"=>"Kristian", "family"=>"Garza", "literal"=>"K. J. Garza", "orcid"=>"http://orcid.org/0000-0003-3484-6875", "github"=>"https://github.com/kjgarza", "updated"=>"2017-06-12T13:40:13.000Z"})
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      datacenter = response[:data].first
      expect(datacenter["attributes"]["title"]).to eq("027.7 - Zeitschrift f\u00FCr Bibliothekskultur")
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
      expect(response[:meta]["member-types"].first).to eq("id"=>"allocating", "title"=>"Allocating", "count"=>40)
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
