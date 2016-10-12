require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resource-types"]["dataset"]).to eq(2708765)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.15468/DL.IEBRZQ")
    end

    it "one" do
      response = subject.get_works(id: "10.6084/M9.FIGSHARE.C.1909847")
      work = response[:data]
      expect(work["attributes"]["author"].first).to eq("literal"=>"Carly Strasser", "orcid"=>"http://orcid.org/0000-0001-9592-2339")
    end

    it "query" do
      response = subject.get_works(query: "mabbett")
      expect(response[:meta]["resource-types"]["dataset"]).to eq(15)
      work = response[:data].first
      expect(work["id"]).to eq("https://doi.org/10.6084/M9.FIGSHARE.1419601")
    end
  end

  context "get_contributors" do
    it "all" do
      response = subject.get_contributors
      expect(response[:meta]).to eq("total"=>7141)
      contributor = response[:data].first
      expect(contributor["id"]).to eq("https://github.com/mne-tools")
    end

    it "one" do
      response = subject.get_contributors(id: "orcid.org/0000-0002-4000-4167")
      contributor = response[:data]
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "literal"=>nil, "orcid"=>"0000-0002-4000-4167", "github"=>nil, "updated"=>"1970-01-01T00:00:00Z"})
    end

    it "query" do
      response = subject.get_contributors(query: "mabbett")
      expect(response[:meta]).to eq("total"=>1)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0001-5882-6823", "type"=>"contributors", "attributes"=>{"given"=>"Andy", "family"=>"Mabbett", "literal"=>nil, "orcid"=>"0000-0001-5882-6823", "github"=>nil, "updated"=>"1970-01-01T00:00:00Z"})
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      expect(response[:meta]["registration-agencies"]["datacite"]).to eq(798)
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
      expect(response[:meta]).to eq("total"=>1, "registration-agencies"=>{"datacite"=>1}, "members"=>{"cern"=>1})
      datacenter = response[:data].first
      expect(datacenter["id"]).to eq("cern.zenodo")
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]["member-types"]).to eq("allocating"=>30, "non-allocating"=>8)
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
      expect(response[:meta]["member-types"]["allocating"]).to eq(1)
      member = response[:data].first
      expect(member["id"]).to eq("tib")
    end
  end

  context "get_sources" do
    it "all" do
      response = subject.get_sources
      expect(response[:meta]).to eq("total"=>15, "groups"=>{"relations"=>6, "contributions"=>4, "publishers"=>2, "results"=>3})
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
      expect(response[:meta]).to eq("total"=>3, "groups"=>{"relations"=>2, "publishers"=>1})
      source = response[:data].first
      expect(source["attributes"]["title"]).to eq("Crossref (DataCite)")
    end
  end

  context "get_relations" do
    it "all" do
      response = subject.get_relations(timeout: 10)
      expect(response).to eq(:data=>[], :included=>[], :errors=>[{"status"=>408, "title"=>"Request timeout"}], :meta=>{})
    end

    it "by work" do
      response = subject.get_relations("work-id" => "10.6084/M9.FIGSHARE.3394312", timeout: 30)
      expect(response[:meta]).to eq("total"=>1, "sources"=>{"datacite-related"=>1}, "relation-types"=>{"is-identical-to"=>1})
      relation = response[:data].first
      expect(relation["attributes"]).to eq("subj-id"=>"http://doi.org/10.6084/M9.FIGSHARE.3394312.V1", "obj-id"=>"http://doi.org/10.6084/M9.FIGSHARE.3394312", "doi"=>"10.6084/M9.FIGSHARE.3394312.V1", "author"=>[{"given"=>"Samuel", "family"=>"Asumadu-Sarkodie", "orcid"=>"http://orcid.org/0000-0001-5035-5983"}, {"given"=>"Phebe Asantewaa", "family"=>"Owusu", "orcid"=>"http://orcid.org/0000-0001-7364-1640"}], "title"=>"Global Annual Installations 2000-2013", "container-title"=>"Figshare", "source-id"=>"datacite-related", "publisher-id"=>"CDL.DIGSCI", "registration-agency-id"=>nil, "relation-type-id"=>"is-identical-to", "type"=>nil, "total"=>1, "published"=>"2016", "issued"=>"2016-05-20T20:40:22Z", "updated"=>"2016-06-01T20:01:21Z")
    end
  end

  context "get_contributions" do
    it "all" do
      response = subject.get_contributions
      expect(response[:meta]["sources"]["datacite-related"]).to eq(4516)
      contribution = response[:data].first
      expect(contribution["attributes"]["subj-id"]).to eq("http://orcid.org/0000-0001-7629-2140")
    end

    it "by contributor" do
      response = subject.get_contributions("contributor-id" => "orcid.org/0000-0002-8635-8390")
      expect(response[:meta]["sources"]["datacite-related"]).to eq(234)
      contribution = response[:data].first
      expect(contribution["attributes"]["subj-id"]).to eq("http://orcid.org/0000-0002-8635-8390")
    end


    it "by publisher/datacenter" do

      response = subject.get_contributions("publisher-id" => "DK.GBIF")
      expect(response[:meta]["sources"].length).to eq(1)
      expect(response[:meta]["publishers"].has_key?("dk.gbif")).to eq(true)
      fullresponse = subject.get_contributions
      expect(response[:data].length).to be <= fullresponse[:data].length
      result = response[:data].select { |obj| obj["type"] == "publishers" }
      expect(result[0]["type"]).to eq("publishers")
    end


  end
end
