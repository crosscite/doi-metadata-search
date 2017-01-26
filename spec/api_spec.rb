require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>2942316)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.4225/35/588805FA8DD28")
    end

    it "one" do
      response = subject.get_works(id: "10.2314/COSCV2.53")
      work = response[:data]
      expect(work["attributes"]["author"].first).to eq("family"=>"Pampel", "given"=>"Heinz", "orcid"=>"http://orcid.org/0000-0003-3334-2771")
      expect(response[:included].size).to eq(5)
      resource_type = response[:included][3]
      expect(resource_type).to eq("id"=>"text", "type"=>"resource-types", "attributes"=>{"title"=>"Text", "updated"=>"2016-09-21T00:00:00Z"})
    end

    it "query" do
      response = subject.get_works(query: "mabbett")
      expect(response[:meta]["resource-types"].first).to eq("id"=>"dataset", "title"=>"Dataset", "count"=>15)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.6084/M9.FIGSHARE.1371114.V1")
    end
  end

  context "get_people" do
    it "all" do
      response = subject.get_people
      expect(response[:meta]).to eq("total"=>7141)
      contributor = response[:data].first
      expect(contributor["id"]).to eq("http://orcid.org/0000-0002-7304-0535")
    end

    it "one" do
      response = subject.get_people(id: "orcid.org/0000-0002-4000-4167")
      contributor = response[:data]
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "literal"=>nil, "orcid"=>"0000-0002-4000-4167", "github"=>nil, "updated"=>"1970-01-01T00:00:00Z"})
    end

    it "query" do
      response = subject.get_people(query: "mabbett")
      expect(response[:meta]).to eq("total"=>1)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0001-5882-6823", "type"=>"contributors", "attributes"=>{"given"=>"Andy", "family"=>"Mabbett", "literal"=>nil, "orcid"=>"0000-0001-5882-6823", "github"=>nil, "updated"=>"1970-01-01T00:00:00Z"})
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      expect(response[:meta]["registration-agencies"].first).to eq("id"=>"datacite", "title"=>"DataCite", "count"=>814)
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
      expect(response[:meta]["members"]).to eq([{"id"=>"cern", "title"=>"European Organization for Nuclear Research", "count"=>1}])
      datacenter = response[:data].first
      expect(datacenter["id"]).to eq("cern.zenodo")
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]["member-types"].first).to eq("id"=>"allocating", "title"=>"Allocating", "count"=>33)
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

  context "get_sources" do
    it "all" do
      response = subject.get_sources
      expect(response[:meta]["groups"].first).to eq("id"=>"relations", "title"=>"Relations", "count"=>6)
      source = response[:data].first
      expect(source["attributes"]["title"]).to eq("Crossref (DataCite)")
    end

    it "one" do
      response = subject.get_sources(id: "datacite-crossref")
      source = response[:data]
      expect(source["attributes"]["title"]).to eq("DataCite (Crossref)")
    end

    it "query" do
      response = subject.get_sources(query: "cross")
      expect(response[:meta]["groups"].first).to eq("id"=>"relations", "title"=>"Relations", "count"=>2)
      source = response[:data].first
      expect(source["attributes"]["title"]).to eq("Crossref (DataCite)")
    end
  end

  context "get_relations" do
    it "all" do
      response = subject.get_relations(timeout: 10)
      expect(response).to eq(:data=>[], :included=>[], :errors=>[], :meta=>{"total"=>nil, "sources"=>nil, "data-centers"=>nil, "relation-types"=>nil})
    end

    # it "by work" do
    #   response = subject.get_relations("work-id" => "10.6084/M9.FIGSHARE.3394312", timeout: 30)
    #   expect(response[:meta]["relation-types"]).to eq([{"id"=>"is_identical_to", "title"=>"Is identical to", "count"=>1}])
    #   relation = response[:data].first
    #   expect(relation["attributes"]["subj-id"]).to eq("http://doi.org/10.6084/M9.FIGSHARE.3394312.V1")
    # end
  end

  context "get_contributions" do
    it "all" do
      response = subject.get_contributions
      expect(response[:meta]["sources"].first).to eq("id"=>"datacite_orcid", "title"=>"DataCite (ORCID)", "count"=>1071634)
      contribution = response[:data].first
      expect(contribution["attributes"]["subj-id"]).to eq("http://orcid.org/0000-0001-6280-8695")
    end

    it "by person" do
      response = subject.get_contributions("contributor-id" => "orcid.org/0000-0002-8635-8390")
      expect(response[:meta]["sources"].first).to eq("id"=>"datacite_orcid", "title"=>"DataCite (ORCID)", "count"=>162040)
      contribution = response[:data].first
      expect(contribution["attributes"]["subj-id"]).to eq("http://orcid.org/0000-0002-8635-8390")
    end


    it "by data center" do
      response = subject.get_contributions("data-center-id" => "DK.GBIF")
      expect(response[:meta]["sources"].length).to eq(1)
      expect(response[:meta]["data-centers"].first).to eq("id"=>"dk.gbif", "title"=>"Global Biodiversity Information Facility", "count"=>20)
      fullresponse = subject.get_contributions
      expect(response[:data].length).to be <= fullresponse[:data].length
      data_center = response[:included].find { |i| i["type"] == "data-centers" }
      expect(data_center["id"]).to eq("dk.gbif")
    end


  end
end
