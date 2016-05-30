require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]).to eq("resource-types"=>{"dataset"=>2490849, "other"=>870671, "text"=>844331, "image"=>689356, "collection"=>310619, "physical-object"=>34335, "software"=>13560, "event"=>6466, "audiovisual"=>5607, "film"=>965, "model"=>533, "interactive-resource"=>295, "sound"=>235, "workflow"=>209, "service"=>19}, "years"=>{}, "publishers"=>{}, "total"=>6582973)
      work = response[:data].first
      expect(work).to eq("id"=>"http://doi.org/10.7891/E-MANUSCRIPTA-45062", "type"=>"works", "attributes"=>{"doi"=>"10.7891/E-MANUSCRIPTA-45062", "author"=>[], "title"=>nil, "container-title"=>nil, "description"=>nil, "resource-type-general"=>nil, "resource-type"=>nil, "type"=>nil, "license"=>nil, "publisher-id"=>"ethz.unknown", "member-id"=>"ethz", "registration-agency-id"=>"datacite", "results"=>{}, "published"=>nil, "issued"=>"2016-05-28T16:30:08Z", "updated"=>nil})
    end

    it "one" do
      response = subject.get_works(id: "10.6084/M9.FIGSHARE.C.1909847")
      work = response[:data].first
      expect(work).to eq("id"=>"http://doi.org/10.6084/M9.FIGSHARE.C.1909847", "type"=>"works", "attributes"=>{"doi"=>"10.6084/M9.FIGSHARE.C.1909847", "author"=>[{"family"=>"Strasser", "given"=>"Carly", "orcid"=>"http://orcid.org/0000-0001-9592-2339"}, {"family"=>"Cruse", "given"=>"Patricia"}, {"family"=>"Kunze", "given"=>"John"}, {"family"=>"Abrams", "given"=>"Stephen"}], "title"=>"DataUp manuscript data", "container-title"=>"Figshare", "description"=>nil, "resource-type-general"=>"collection", "resource-type"=>"Collection", "type"=>nil, "license"=>"https://creativecommons.org/licenses/by/3.0/us/", "publisher-id"=>"cdl.digsci", "member-id"=>"cdl", "registration-agency-id"=>"datacite", "results"=>{}, "published"=>"2015", "issued"=>"2015-12-04T15:40:42Z", "updated"=>"2016-03-11T10:57:59Z"})
    end

    it "query" do
      response = subject.get_works(q: "mabbett")
      expect(response[:meta]).to eq("resource-types"=>{"dataset"=>15, "text"=>1}, "years"=>{}, "publishers"=>{}, "total"=>16)
      work = response[:data].first
      expect(work).to eq("id"=>"http://doi.org/10.6084/M9.FIGSHARE.1419601", "type"=>"works", "attributes"=>{"doi"=>"10.6084/M9.FIGSHARE.1419601", "author"=>[{"family"=>"Mabbett", "given"=>"Andy", "orcid"=>"http://orcid.org/0000-0001-5882-6823"}], "title"=>"2015-05-13 - Authority control in Wikipedia - Qatar", "container-title"=>"Figshare", "description"=>nil, "resource-type-general"=>"dataset", "resource-type"=>"Presentation", "type"=>"dataset", "license"=>"https://creativecommons.org/licenses/by/3.0/us/", "publisher-id"=>"cdl.digsci", "member-id"=>"cdl", "registration-agency-id"=>"datacite", "results"=>{}, "published"=>"2015", "issued"=>"2015-05-19T15:57:08Z", "updated"=>"2015-05-19T15:57:08Z"})
    end
  end

  context "get_contributors" do
    it "all" do
      response = subject.get_contributors
      expect(response[:meta]).to eq("total"=>5637)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"https://github.com/mne-tools", "type"=>"contributors", "attributes"=>{"given"=>nil, "family"=>nil, "literal"=>"mne-tools", "orcid"=>nil, "github"=>"mne-tools", "updated"=>"1970-01-01T00:00:00Z"})
    end

    it "one" do
      response = subject.get_contributors(id: "orcid.org/0000-0002-4000-4167")
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "literal"=>nil, "orcid"=>"0000-0002-4000-4167", "github"=>nil, "updated"=>"1970-01-01T00:00:00Z"})
    end

    it "query" do
      response = subject.get_contributors(q: "mabbett")
      expect(response[:meta]).to eq("total"=>1)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0001-5882-6823", "type"=>"contributors", "attributes"=>{"given"=>"Andy", "family"=>"Mabbett", "literal"=>nil, "orcid"=>"0000-0001-5882-6823", "github"=>nil, "updated"=>"1970-01-01T00:00:00Z"})
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      expect(response[:meta]).to eq("total"=>725, "total-pages"=>29, "page"=>1, "registration-agencies"=>{"datacite"=>725})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"ethz.ubasojs", "type"=>"publishers", "attributes"=>{"title"=>"027.7 - Zeitschrift für Bibliothekskultur", "other-names"=>[], "prefixes"=>[], "member-id"=>"ethz", "registration-agency-id"=>"datacite", "updated"=>"2016-05-29T11:30:57Z"})
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenter = response[:data]
      expect(datacenter).to eq("id"=>"cern.zenodo", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"cern", "registration-agency-id"=>"datacite", "updated"=>"2016-05-29T14:38:17Z"})
    end

    it "query" do
      response = subject.get_datacenters(q: "zeno")
      expect(response[:meta]).to eq("total"=>1, "total-pages"=>1, "page"=>1, "registration-agencies"=>{"datacite"=>1})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"cern.zenodo", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"cern", "registration-agency-id"=>"datacite", "updated"=>"2016-05-29T14:38:17Z"})
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]).to eq("total"=>34, "member-types"=>{"allocating"=>27, "non-allocating"=>7}, "regions"=>{"amer"=>7, "apac"=>5, "emea"=>22}, "years"=>{"2015"=>5, "2014"=>4, "2013"=>4, "2012"=>1, "2011"=>1, "2010"=>9, "2009"=>7})
      member = response[:data].first
      expect(member).to eq("id"=>"ands", "type"=>"members", "attributes"=>{"title"=>"Australian National Data Service (ANDS)", "description"=>"", "member-type"=>"full", "region"=>"Asia Pacific", "country"=>"Australia", "year"=>2010, "updated"=>nil})
    end

    it "one" do
      response = subject.get_members(id: "ANDS")
      member = response[:data]
      expect(member).to eq("id"=>"ands", "type"=>"members", "attributes"=>{"title"=>"Australian National Data Service (ANDS)", "description"=>"", "member-type"=>"full", "region"=>"Asia Pacific", "country"=>"Australia", "year"=>2010, "updated"=>nil})
    end

    it "query" do
      response = subject.get_members(q: "tib")
      expect(response[:meta]).to eq("total"=>1, "member-types"=>{"allocating"=>1}, "regions"=>{"emea"=>1}, "years"=>{"2009"=>1})
      member = response[:data].first
      expect(member).to eq("id"=>"tib", "type"=>"members", "attributes"=>{"title"=>"German National Library of Science and Technology (TIB)", "description"=>"", "member-type"=>"full", "region"=>"EMEA", "country"=>"Germany", "year"=>2009, "updated"=>nil})
    end
  end

  context "get_sources" do
    it "all" do
      response = subject.get_sources
      expect(response[:meta]).to eq("total"=>15, "groups"=>{"relations"=>6, "contributions"=>4, "publishers"=>2, "results"=>3})
      source = response[:data].first
      expect(source).to eq("id"=>"crossref-datacite", "type"=>"sources", "attributes"=>{"title"=>"Crossref (DataCite)", "description"=>"Import works linked to a DataCite DOI from Crossref.", "state"=>"active", "group-id"=>"relations", "work-count"=>0, "relation-count"=>0, "result-count"=>0, "by-day"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "by-month"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "updated"=>"2016-05-29T13:05:07Z"})
    end

    it "one" do
      response = subject.get_sources(id: "datacite-crossref")
      source = response[:data].first
      expect(source).to eq("id"=>"datacite-crossref", "type"=>"sources", "attributes"=>{"title"=>"DataCite (Crossref)", "description"=>"Import works with Crossref DOIs as relatedIdentifier via the DataCite Solr API.", "state"=>"active", "group-id"=>"relations", "work-count"=>203772, "relation-count"=>221061, "result-count"=>475263, "by-day"=>{"with-results"=>1, "without-results"=>0, "not-updated"=>221005}, "by-month"=>{"with-results"=>195804, "without-results"=>16710, "not-updated"=>8492}, "updated"=>"2016-05-29T15:17:49Z"})
    end

    it "query" do
      response = subject.get_sources(q: "cross")
      expect(response[:meta]).to eq("total"=>3, "groups"=>{"relations"=>2, "publishers"=>1})
      source = response[:data].first
      expect(source).to eq("id"=>"crossref-datacite", "type"=>"sources", "attributes"=>{"title"=>"Crossref (DataCite)", "description"=>"Import works linked to a DataCite DOI from Crossref.", "state"=>"active", "group-id"=>"relations", "work-count"=>0, "relation-count"=>0, "result-count"=>0, "by-day"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "by-month"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "updated"=>"2016-05-29T13:05:07Z"})
    end
  end

  context "get_relations" do
    it "all" do
      response = subject.get_relations
      expect(response[:meta]).to eq("total"=>5485191, "sources"=>{"datacite-related"=>4409016, "datacite-orcid"=>4, "datacite-github"=>2167, "mendeley"=>2, "github"=>386, "europe-pmc-fulltext"=>42, "datacite-crossref"=>1073574}, "relation-types"=>{"cites"=>1052, "is-cited-by"=>1002, "is-supplement-to"=>473548, "is-supplemented-by"=>473550, "continues"=>51, "is-continued-by"=>45, "is-metadata-for"=>31, "has-metadata"=>31, "is-part-of"=>110520, "has-part"=>110201, "references"=>2126384, "is-referenced-by"=>2126432, "documents"=>1767, "is-documented-by"=>1750, "compiles"=>27, "reviews"=>1000, "is-reviewed-by"=>1000, "is-derived-from"=>14073, "is-source-of"=>14552, "bookmarks"=>111, "is-new-version-of"=>10895, "is-previous-version-of"=>10905, "is-original-form-of"=>3130, "is-variant-form-of"=>2591, "is-identical-to"=>418, "is-compiled-by"=>27, "is-bookmarked-by"=>98})
      relation = response[:data].first
      expect(relation).to eq("id"=>"8a9c5431-5557-4189-8b0c-98c0b7d4b72f", "type"=>"relations", "attributes"=>{"subj-id"=>"http://doi.org/10.5194/CP-12-171-2016", "obj-id"=>"http://doi.org/10.1594/PANGAEA.849156", "doi"=>"10.5194/CP-12-171-2016", "author"=>[], "title"=>"Spatial and temporal oxygen isotope variability in northern Greenland – implications for a new climate record over the past millennium", "container-title"=>nil, "source-id"=>"datacite-crossref", "publisher-id"=>"3145", "registration-agency-id"=>"crossref", "relation-type-id"=>"is-referenced-by", "type"=>nil, "total"=>1, "published"=>"2016-02-03", "issued"=>"2016-02-03T00:00:00Z", "updated"=>"2016-05-28T10:10:26Z"})
    end

    it "by work" do
      response = subject.get_relations("work-id" => "10.6084/M9.FIGSHARE.3394312")
      expect(response[:meta]).to eq("total"=>1, "sources"=>{"datacite-related"=>1}, "relation-types"=>{"is-identical-to"=>1})
      relation = response[:data].first
      expect(relation).to eq("id"=>"9fe887ae-0013-466a-ac86-380316a7b218", "type"=>"relations", "attributes"=>{"subj-id"=>"http://doi.org/10.6084/M9.FIGSHARE.3394312.V1", "obj-id"=>"http://doi.org/10.6084/M9.FIGSHARE.3394312", "doi"=>"10.6084/M9.FIGSHARE.3394312.V1", "author"=>[], "title"=>"Global Annual Installations 2000-2013", "container-title"=>nil, "source-id"=>"datacite-related", "publisher-id"=>"CDL.DIGSCI", "registration-agency-id"=>nil, "relation-type-id"=>"is-identical-to", "type"=>nil, "total"=>1, "published"=>"2016", "issued"=>"2016-05-20T20:40:22Z", "updated"=>"2016-05-22T20:52:10Z"})
    end
  end

  context "get_contributions" do
    it "all" do
      response = subject.get_contributions
      expect(response[:meta]).to eq("total"=>1067682, "sources"=>{"datacite-related"=>130, "datacite-orcid"=>1063931, "github-contributor"=>152, "datacite-search-link"=>3469})
      contribution = response[:data].first
      expect(contribution).to eq("id"=>"cd37482b-af89-428f-8d78-f66c9daa5e77", "type"=>"contributions", "attributes"=>{"doi"=>"10.13140/2.1.4110.8481", "credit-name"=>"José Amendoeira", "orcid"=>"0000-0002-4464-8517", "author"=>[{"family"=>"Seabra", "given"=>"Paulo"}, {"family"=>"Santos", "given"=>"Alexandra"}, {"family"=>"Garcia", "given"=>"Lurdes"}, {"family"=>"Amendoeira", "given"=>"José"}, {"family"=>"Sá", "given"=>"Luís"}], "title"=>"Drug addiction", "container-title"=>"Unpublished", "source-id"=>"datacite-search-link", "contributor-role-id"=>"contribution", "type"=>nil, "published"=>"2012", "issued"=>"2014-10-29T21:16:03Z", "updated"=>"2016-05-29T12:12:26Z"})
    end

    it "by contributor" do
      response = subject.get_contributions("contributor-id" => "orcid.org/0000-0002-8635-8390")
      expect(response[:meta]).to eq("total"=>162010, "sources"=>{"datacite-related"=>3, "datacite-orcid"=>162004, "datacite-search-link"=>3})
      contribution = response[:data].first
      expect(contribution).to eq("id"=>"8ea09e4d-e3f9-4b0e-814f-4941f7b0179e", "type"=>"contributions", "attributes"=>{"doi"=>"10.6084/M9.FIGSHARE.1126238", "credit-name"=>"Henry Rzepa", "orcid"=>"0000-0002-8635-8390", "author"=>[{"given"=>"Henry S.", "family"=>"Rzepa", "orcid"=>"http://orcid.org/0000-0002-8635-8390"}], "title"=>"Gaussian Job Archive for C50H66N6O2", "container-title"=>"Figshare", "source-id"=>"datacite-orcid", "contributor-role-id"=>"contribution", "type"=>nil, "published"=>"2014", "issued"=>"2014-08-08T15:31:07Z", "updated"=>"2016-05-28T07:41:10Z"})
    end
  end
end
