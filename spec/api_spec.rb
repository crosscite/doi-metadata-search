require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>66076)
      work = response[:data].first
      expect(work["id"]).to eq("https://handle.test.datacite.org/10.0133/51988")
    end

    it "one" do
      response = subject.get_works(id: "10.70001/12334296")
      work = response[:data]
      expect(work.dig("attributes", "author").first).to eq({"literal"=>"Joyce Mott Anderson"})
      expect(response[:included].size).to eq(3)
      data_center = response[:included][0]
      expect(data_center).to eq("attributes" => {"created"=>"2011-12-07T13:43:39.000Z", "member-id"=>"datacite", "other-names"=>[], "prefixes"=>[], "title"=>"DataCite Repository", "updated"=>"2019-08-24T06:22:34.000Z", "year"=>2011},
        "id" => "datacite.datacite",
        "relationships" => {"member"=>{"data"=>{"id"=>"datacite", "type"=>"members"}}},
        "type" => "data-centers")
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
      expect(work["id"]).to eq("https://handle.test.datacite.org/10.0133/51988")
    end

    it "query" do
      response = subject.get_works(query: "california")
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>334)
      work = response[:data].first
      expect(work["id"]).to eq("https://handle.test.datacite.org/10.0311/fk2/acdee248afe2e8923935a04b50537302")
    end
  end

  context "get_people" do
    it "all" do
      response = subject.get_people
      expect(response[:meta]).to eq("total"=>62423, "totalPages"=>400, "page"=>1)
      contributor = response[:data].first
      expect(contributor["id"]).to eq("0000-0002-2220-6072")
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
      expect(datacenter["attributes"]["title"]).to eq("027.7 - Zeitschrift für Bibliothekskultur")
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenter = response[:data]
      expect(datacenter["id"]).to eq("cern.zenodo")
    end

    it "query" do
      response = subject.get_datacenters(query: "zenodo")
      expect(response[:meta]["members"].first).to eq("id"=>"cern", "title"=>"CERN - European Organization for Nuclear Research", "count"=>1)
      datacenter = response[:data].first
      expect(datacenter["id"]).to eq("cern.zenodo")
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]["regions"].first).to eq("id"=>"amer", "title"=>"Americas", "count"=>48)
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
      expect(response[:meta]["regions"].first).to eq("id"=>"apac", "title"=>"Asia Pacific", "count"=>1)
      member = response[:data].first
      expect(member["id"]).to eq("ands")
    end
  end


  context "get_events" do
    it "all" do
      response = subject.get_events
      expect(response[:meta]["sources"].first).to eq("count"=>1692284, "id"=>"crossref", "title"=>"Crossref to DataCite")
      event = response[:data].first
      expect(event["type"]).to eq("events")
      expect(event.dig("attributes", "subjId")).to eq("https://api.test.datacite.org/reports/a8025c2b-ae9f-48d8-8dc3-d1133fff1502")
    end

    it "one doi" do
      response = subject.get_events("objId" => "https://doi.org/10.7272/q6g15xs4")
      events = response[:data]
      expect(events.first.dig("attributes", "subjId")).to eq("https://api.test.datacite.org/reports/961e7eaa-7c3a-485a-85ed-94f94a535519")
      expect(response[:meta]["relationTypes"].size).to eq(4)
      type = response[:meta]["relationTypes"][0]
      expect(type).to eq({"id"=>"total-dataset-investigations-regular", "title"=>"total-dataset-investigations-regular", "count"=>666.0, "yearMonths" => [{"id"=>"2018-04", "sum"=>391.0, "title"=>"April 2018"}, {"id"=>"2018-05", "sum"=>201.0, "title"=>"May 2018"}, {"id"=>"2018-09", "sum"=>74.0, "title"=>"September 2018"}]})
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
      expect(events.first.dig("attributes","sourceId")).to eq("datacite-usage")
      expect(response[:meta].dig("sources")).to be_a(Array)
    end
  end
end
