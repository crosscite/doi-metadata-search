require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]["resource-types"]).to eq("event" => 6711, "film" => 920, "physical-object" => 6680, "dataset"=>2598715, "text"=>1390919, "other"=>873873, "image"=>704151, "collection"=>351593, "audiovisual" => 7098, "software" => 15895, "model"=>556, "interactive-resource"=>372, "sound"=>243, "workflow"=>221, "service"=>21)
      work = response[:data].first
      expect(work["id"]).to eq("http://doi.org/10.13140/RG.2.1.2068.7608")
    end

    it "one" do
      response = subject.get_works(id: "10.6084/M9.FIGSHARE.C.1909847")
      work = response[:data].first
      expect(work).to eq("id" => "http://doi.org/10.6084/M9.FIGSHARE.C.1909847", "type"=>"works", "attributes" => {"doi"=>"10.6084/M9.FIGSHARE.C.1909847", "url"=>nil, "author"=>[{"literal"=>"Carly Strasser", "orcid"=>"http://orcid.org/0000-0001-9592-2339"}, {"literal"=>"Patricia Cruse"}, {"literal"=>"John Kunze"}, {"literal"=>"Stephen Abrams"}], "title"=>"DataUp manuscript data", "container-title"=>"Figshare", "description"=>nil, "resource-type-general"=>"collection", "resource-type"=>"Collection", "type"=>nil, "license"=>"https://creativecommons.org/licenses/by/3.0/us/", "publisher-id"=>"cdl.digsci", "member-id"=>"cdl", "registration-agency-id"=>"datacite", "results"=>{}, "published"=>"2015", "deposited"=>"2015-12-04T15:40:42Z", "updated"=>"2016-03-11T10:57:59Z"})
    end

    it "query" do
      response = subject.get_works(query: "mabbett")
      expect(response[:meta]).to eq("resource-types"=>{"dataset"=>15, "text"=>1}, "years"=>{"2016"=>6, "2015"=>10}, "publishers"=>{"cdl.digsci"=>15, "tib.r-gate"=>1}, "total"=>16)
      work = response[:data].first
      expect(work["id"]).to eq("http://doi.org/10.6084/M9.FIGSHARE.2903314")
    end
  end

  context "get_contributors" do
    it "all" do
      response = subject.get_contributors
      expect(response[:meta]).to eq("total"=>6897)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"https://github.com/mne-tools", "type"=>"contributors", "attributes"=>{"given"=>nil, "family"=>nil, "literal"=>"mne-tools", "orcid"=>nil, "github"=>"mne-tools", "updated"=>"1970-01-01T00:00:00Z"})
    end

    it "one" do
      response = subject.get_contributors(id: "orcid.org/0000-0002-4000-4167")
      contributor = response[:data].first
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
      expect(response[:meta]).to eq("total"=>761, "registration-agencies"=>{"datacite"=>761}, "members"=>{"delft"=>14, "dk"=>9, "mtakik"=>37, "purdue"=>26, "cdl"=>171, "osti"=>24, "ethz"=>44, "gesis"=>64, "cisti"=>20, "zbmed"=>33, "inist"=>32, "snd"=>6, "cern"=>7, "crui"=>34, "datacite"=>2, "csic"=>1, "spbpu"=>2, "zbw"=>9, "ands"=>42, "jalc"=>1, "nrct"=>1, "tib"=>110, "subgoe"=>3, "estdoi"=>6, "bibsys"=>2, "bl"=>61})
      datacenter = response[:data].first
      expect(datacenter["attributes"]["title"]).to eq("027.7 - Zeitschrift für Bibliothekskultur")
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenters = response[:data]
      expect(datacenters.first).to eq("id"=>"cern.zenodo", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"CERN", "registration-agency-id"=>"datacite", "updated"=>"2016-08-16T09:23:52Z"})
    end

    it "query" do
      response = subject.get_datacenters(query: "zeno")
      expect(response[:meta]).to eq("total"=>1, "registration-agencies"=>{"datacite"=>1}, "members"=>{"cern"=>1})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"cern.zenodo", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"CERN", "registration-agency-id"=>"datacite", "updated"=>"2016-08-16T09:23:52Z"})
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]).to eq("total"=>34, "member-types"=>{"allocating"=>27, "non-allocating"=>7}, "regions"=>{"amer"=>7, "apac"=>5, "emea"=>22}, "years"=>{"2015"=>5, "2014"=>5, "2013"=>4, "2012"=>1, "2011"=>2, "2010"=>9, "2009"=>8})
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
      expect(response[:meta]).to eq("total"=>34, "member-types"=>{"allocating"=>27, "non-allocating"=>7}, "regions"=>{"amer"=>7, "apac"=>5, "emea"=>22}, "years"=>{"2015"=>5, "2014"=>5, "2013"=>4, "2012"=>1, "2011"=>2, "2010"=>9, "2009"=>8})
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
      source = response[:data].first
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
      response = subject.get_relations
      expect(response[:meta]["sources"]).to eq("datacite-related"=>6294928, "datacite-orcid"=>6, "datacite-github"=>4207, "mendeley"=>2, "github"=>386, "europe-pmc-fulltext"=>42, "datacite-crossref"=>1117648)
      relation = response[:data].first
      expect(relation["attributes"]["subj-id"]).to eq("http://doi.org/10.12764/15500_P16")
    end

    it "by work" do
      response = subject.get_relations("work-id" => "10.6084/M9.FIGSHARE.3394312")
      expect(response[:meta]).to eq("total"=>1, "sources"=>{"datacite-related"=>1}, "relation-types"=>{"is-identical-to"=>1})
      relation = response[:data].first
      expect(relation["attributes"]).to eq("subj-id"=>"http://doi.org/10.6084/M9.FIGSHARE.3394312.V1", "obj-id"=>"http://doi.org/10.6084/M9.FIGSHARE.3394312", "doi"=>"10.6084/M9.FIGSHARE.3394312.V1", "author"=>[{"given"=>"Samuel", "family"=>"Asumadu-Sarkodie", "orcid"=>"http://orcid.org/0000-0001-5035-5983"}, {"given"=>"Phebe Asantewaa", "family"=>"Owusu", "orcid"=>"http://orcid.org/0000-0001-7364-1640"}], "title"=>"Global Annual Installations 2000-2013", "container-title"=>"Figshare", "source-id"=>"datacite-related", "publisher-id"=>"CDL.DIGSCI", "registration-agency-id"=>nil, "relation-type-id"=>"is-identical-to", "type"=>nil, "total"=>1, "published"=>"2016", "issued"=>"2016-05-20T20:40:22Z", "updated"=>"2016-06-01T20:01:21Z")
    end
  end

  context "get_contributions" do
    it "all" do
      response = subject.get_contributions
      expect(response[:meta]).to eq("total"=>1077274, "sources"=>{"datacite-related"=>5902, "datacite-orcid"=>1067225, "github-contributor"=>510, "datacite-search-link"=>3637})
      contribution = response[:data].first
      expect(contribution["attributes"]["subj-id"]).to eq("http://orcid.org/0000-0003-2088-6323")
    end

    it "by contributor" do
      response = subject.get_contributions("contributor-id" => "orcid.org/0000-0002-8635-8390")
      expect(response[:meta]).to eq("total"=>162187, "sources"=>{"datacite-related"=>234, "datacite-orcid"=>161940, "datacite-search-link"=>13})
      contribution = response[:data].first
      expect(contribution["attributes"]).to eq("subj-id"=>"http://orcid.org/0000-0002-8635-8390", "obj-id"=>"http://doi.org/10.14469/HPC/1146", "credit-name"=>"Henry Rzepa", "orcid"=>"0000-0002-8635-8390", "github"=>nil, "author"=>[{"family"=>"Rzepa", "given"=>"Henry", "orcid"=>"http://orcid.org/0000-0002-8635-8390"}], "doi"=>"10.14469/HPC/1146", "url"=>nil, "title"=>"RUWFOE model of two boron units Diels Alder cycloaddition, TS with Me replacing NHMe twice, reactant with H-Bonding", "container-title"=>"Imperial College London", "source-id"=>"datacite-orcid", "contributor-role-id"=>"contribution", "type"=>nil, "published"=>"2016", "issued"=>"2016-07-31T17:54:54Z", "updated"=>"2016-08-15T23:34:22Z")
    end
  end
end
