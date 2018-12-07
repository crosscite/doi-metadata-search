require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>6938)
      work = response[:data].first
      expect(work["id"]).to eq("https://handle.test.datacite.org/10.15771/imejidev.rv")
    end

    it "one" do
      response = subject.get_works(id: "10.4124/test94485")
      work = response[:data]
      expect(work["attributes"]["author"].first).to eq("literal"=>"Person_1")
      expect(response[:included].size).to eq(3)
      data_center = response[:included][0]
      expect(data_center).to eq("attributes" => {"created"=>"2014-10-03T15:53:41.000Z", "member-id"=>"bl", "title"=>"Mendeley Data", "updated"=>"2018-08-26T01:30:43.000Z", "year"=>2014},
        "id" => "bl.mendeley",
        "relationships" => {"member"=>{"data"=>{"id"=>"bl", "type"=>"members"}}},
        "type" => "data-centers")
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
      expect(response[:meta]).to eq("total"=>61824, "total-pages"=>2473, "page"=>1)
      contributor = response[:data].first
      expect(contributor["id"]).to eq("0000-0003-1564-2260")
    end

    it "one" do
      response = subject.get_people(id: "0000-0001-6528-2027")
      contributor = response[:data]
      expect(contributor).to eq("id" => "0000-0001-6528-2027", "type"=>"people", "attributes" => {"family"=>"Fenner", "github"=>nil, "given"=>"Martin", "literal"=>"Martin Fenner", "orcid"=>"https://orcid.org/0000-0001-6528-2027", "updated"=>"2018-08-20T16:40:54.000Z"})
    end

    it "query" do
      response = subject.get_people(query: "garza")
      expect(response[:meta]).to eq("total"=>9, "total-pages"=>1, "page"=>1)
      contributor = response[:data][1]
      expect(contributor).to eq("id" => "0000-0002-5099-0079", "type"=>"people", "attributes" => {"family"=>"Cardenas-de la Garza", "github"=>nil, "given"=>"Jesus Alberto", "literal"=>"Jesus Alberto Cardenas-de la Garza", "orcid"=>"https://orcid.org/0000-0002-5099-0079", "updated"=>"2018-05-14T20:22:20.000Z"})
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
      expect(datacenter["id"]).to eq("dk.openaire")
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]["regions"].first).to eq("id"=>"amer", "title"=>"Americas", "count"=>2)
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
      expect(response[:meta]["regions"].first).to eq("id"=>"apac", "title"=>"Asia Pacific", "count"=>1)
      member = response[:data].first
      expect(member["id"]).to eq("ands")
    end
  end


  context "get_events" do
    it "all" do
      response = subject.get_events
      expect(response[:meta]["relation-types"]).to be_a(Array)
      event = response[:data].first
      expect(event["type"]).to eq("events")
      expect(event.dig("attributes")).to have_key("subj-id")
    end

    it "one doi" do
      response = subject.get_events("obj-id" => "https://doi.org/10.7272/q6g15xs4")
      events = response[:data]
      expect(events.first["attributes"]["subj-id"]).to eq("https://api.datacite.org/reports/fa2ad308-1b25-4394-9bc6-e0c7511e763d")
      expect(response[:meta]["relation-types"].size).to eq(6)
      type = response[:meta]["relation-types"][0]
      expect(type).to eq({"id"=>"total-dataset-investigations-regular", "title"=>"total-dataset-investigations-regular", "count"=>13, "year-months"=>[{"id"=>"2018-04", "title"=>"April 2018", "sum"=>120.0}, {"id"=>"2018-05", "title"=>"May 2018", "sum"=>382.0}, {"id"=>"2018-06", "title"=>"June 2018", "sum"=>33.0}, {"id"=>"2018-07", "title"=>"July 2018", "sum"=>36.0}, {"id"=>"2018-08", "title"=>"August 2018", "sum"=>29.0}, {"id"=>"2018-09", "title"=>"September 2018", "sum"=>4.0}, {"id"=>"2018-11", "title"=>"November 2018", "sum"=>31.0}, {"id"=>"2018-12", "title"=>"December 2018", "sum"=>1.0}]})
    end


    it "one not found" do
      response = subject.get_events("obj-id" => "https://doi.org/10.4226/xxxx")
      event = response[:data]
      expect(event).to be_empty
    end

    it "filter by source and filter pages" do
      response = subject.get_events("source-id" => "datacite-usage", "page[size]" =>3)
      events = response[:data]
      expect(events.size).to eq(3)
      expect(events.first.dig("attributes","source-id")).to eq("datacite-usage")
      expect(response[:meta].dig("sources")).to be_a(Array)
    end

    it "query" do
      response = subject.get_events(query: "10.7272/q6g15xs4")
      event = response[:data].first
      expect(event["id"]).to eq("308185f3-1607-478b-a25e-ed5671994db5")
    end
  end
end
