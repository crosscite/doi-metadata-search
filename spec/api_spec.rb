require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]).to eq("resource-types"=>{"dataset"=>2530173, "text"=>1309569, "other"=>872249, "image"=>694451, "collection"=>313746, "software"=>14683, "physical-object"=>6688, "event"=>6557, "audiovisual"=>6171, "film"=>967, "model"=>539, "interactive-resource"=>321, "sound"=>240, "workflow"=>218, "service"=>21}, "years"=>{"2016"=>395824, "2015"=>2044515, "2014"=>922708, "2013"=>333117, "2012"=>211537, "2011"=>337643, "2010"=>142954, "2007"=>158014, "2006"=>144119, "2005"=>162237}, "publishers"=>{"cdl.dplanet"=>861878, "bl.ccdc"=>611424, "ethz.seals"=>511650, "estdoi.bio"=>487448, "cdl.digsci"=>387189, "tib.r-gate"=>373556, "gesis.die"=>373193, "ethz.epics-ba"=>348365, "tib.pangaea"=>345569, "bl.imperial"=>189735}, "total"=>6857896)
      work = response[:data].first
      expect(work).to eq("id"=>"http://doi.org/10.7891/E-MANUSCRIPTA-45062", "type"=>"works", "attributes"=>{"doi"=>"10.7891/E-MANUSCRIPTA-45062", "author"=>[], "title"=>nil, "container-title"=>nil, "description"=>nil, "resource-type-general"=>nil, "resource-type"=>nil, "type"=>nil, "license"=>nil, "publisher-id"=>"ethz.unknown", "member-id"=>"ethz", "registration-agency-id"=>"datacite", "results"=>{}, "published"=>nil, "issued"=>"2016-05-28T16:30:08Z", "updated"=>nil})
    end

    it "one" do
      response = subject.get_works(id: "10.6084/M9.FIGSHARE.C.1909847")
      work = response[:data].first
      expect(work).to eq("id"=>"http://doi.org/10.6084/M9.FIGSHARE.C.1909847", "type"=>"works", "attributes"=>{"doi"=>"10.6084/M9.FIGSHARE.C.1909847", "url"=>nil, "author"=>[{"family"=>"Strasser", "given"=>"Carly", "orcid"=>"http://orcid.org/0000-0001-9592-2339"}, {"family"=>"Cruse", "given"=>"Patricia"}, {"family"=>"Kunze", "given"=>"John"}, {"family"=>"Abrams", "given"=>"Stephen"}], "title"=>"DataUp manuscript data", "container-title"=>"Figshare", "description"=>nil, "resource-type-general"=>"collection", "resource-type"=>"Collection", "type"=>nil, "license"=>"https://creativecommons.org/licenses/by/3.0/us/", "publisher-id"=>"cdl.digsci", "member-id"=>"cdl", "registration-agency-id"=>"datacite", "results"=>{}, "published"=>"2015", "deposited"=>"2015-12-04T15:40:42Z", "updated"=>"2016-03-11T10:57:59Z"})
    end

    it "query" do
      response = subject.get_works(query: "mabbett")
      expect(response[:meta]).to eq("resource-types"=>{"dataset"=>15, "text"=>1}, "years"=>{"2016"=>6, "2015"=>10}, "publishers"=>{"cdl.digsci"=>15, "tib.r-gate"=>1}, "total"=>16)
      work = response[:data].first
      expect(work).to eq("id"=>"http://doi.org/10.6084/M9.FIGSHARE.1419601", "type"=>"works", "attributes"=>{"doi"=>"10.6084/M9.FIGSHARE.1419601", "author"=>[{"family"=>"Mabbett", "given"=>"Andy", "orcid"=>"http://orcid.org/0000-0001-5882-6823"}], "title"=>"2015-05-13 - Authority control in Wikipedia - Qatar", "container-title"=>"Figshare", "description"=>nil, "resource-type-general"=>"dataset", "resource-type"=>"Presentation", "type"=>"dataset", "license"=>"https://creativecommons.org/licenses/by/3.0/us/", "publisher-id"=>"cdl.digsci", "member-id"=>"cdl", "registration-agency-id"=>"datacite", "results"=>{}, "published"=>"2015", "issued"=>"2015-05-19T15:57:08Z", "updated"=>"2015-05-19T15:57:08Z"})
    end
  end

  context "get_contributors" do
    it "all" do
      response = subject.get_contributors
      expect(response[:meta]).to eq("total"=>6445)
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
      expect(response[:meta]).to eq("total"=>746, "registration-agencies"=>{"datacite"=>746}, "members"=>{"delft"=>14, "dk"=>9, "mtakik"=>37, "purdue"=>25, "cdl"=>169, "osti"=>24, "ethz"=>43, "gesis"=>64, "cisti"=>19, "zbmed"=>31, "inist"=>30, "snd"=>6, "cern"=>7, "crui"=>33, "datacite"=>2, "csic"=>1, "zbw"=>9, "ands"=>41, "jalc"=>1, "nrct"=>1, "tib"=>108, "subgoe"=>3, "estdoi"=>6, "bibsys"=>2, "bl"=>61})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"ethz.ubasojs", "type"=>"publishers", "attributes"=>{"title"=>"027.7 - Zeitschrift für Bibliothekskultur", "other-names"=>[], "prefixes"=>[], "member-id"=>"ETHZ", "registration-agency-id"=>"datacite", "updated"=>"2016-07-01T20:39:55Z"})
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenters = response[:data]
      expect(datacenters.first).to eq("id"=>"cern.zenodo", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"CERN", "registration-agency-id"=>"datacite", "updated"=>"2016-07-01T21:17:32Z"})
    end

    it "query" do
      response = subject.get_datacenters(query: "zeno")
      expect(response[:meta]).to eq("total"=>1, "registration-agencies"=>{"datacite"=>1}, "members"=>{"cern"=>1})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"cern.zenodo", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"cern", "registration-agency-id"=>"datacite", "updated"=>"2016-05-29T14:38:17Z"})
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]).to eq("total"=>34, "member-types"=>{"allocating"=>27, "non-allocating"=>7}, "regions"=>{"amer"=>7, "apac"=>5, "emea"=>22}, "years"=>{"2015"=>5, "2014"=>4, "2013"=>4, "2012"=>1, "2011"=>1, "2010"=>9, "2009"=>7})
      member = response[:data].first
      expect(member).to eq("id"=>"ands", "type"=>"members", "attributes"=>{"title"=>"Australian National Data Service", "description"=>"<p>The task of the Australian National Data Service (ANDS) is to build the Australian Research Data Commons by creating the infrastructure to enable Australian researchers to easily publish, discover, access and reuse research data.</p>\n\n<p>Our approach is to engage in partnerships with research institutions to encourage better local data management, which enables structured collections to be created and information about these collections to be published via <a href=\"http://researchdata.ands.org.au/\">Research Data Australia</a>, a discovery service provided by ANDS to help researchers to find and access Australian research data. It contains descriptions of research data that is held by contributing organisations and institutions.</p>\n\n<p>ANDS involvement in the DataCite consortium ensures that we are active in global initiatives addressing the issues surrounding research data, including those of publication, citation and standards. ANDS has run its <a href=\"http://ands.org.au/services/cite-my-data.html\">Cite My Data</a> service since 2011. This service allows Australian research organisations to assign DOIs to their own research collections. This, in turn, provides researchers with a means of citing their published data and achieving recognition for their research data output.</p>\n\n<p>Subscribe to our discussion list: <a href=\"https://groups.google.com/forum/?hl=en#!forum/ands-general\">ANDS Google Group</a>.</p>\n\n<p>Subscribe to our e-newsletter: <a href=\"http://us7.campaign-archive2.com/home/?u=b542ef52e49302569068046d9&amp;id=22b849a4ee\">andsUP</a>.</p>\n\n<p>Telephone: +61 3 9902 0585<br>\nE-Mail: contact [at] ands.org.au</p>\n", "member-type"=>"allocating", "region"=>"Asia Pacific", "country"=>"Australia", "year"=>2010, "logo-url"=>"https://assets.datacite.org/images/members/ands.jpg", "email"=>nil, "website"=>"http://www.ands.org.au", "phone"=>nil, "updated"=>"2016-06-09T18:04:28.000Z"})
    end

    it "one" do
      response = subject.get_members(id: "ANDS")
      member = response[:data]
      expect(member).to eq("id"=>"ands", "type"=>"members", "attributes"=>{"title"=>"Australian National Data Service", "description"=>"<p>The task of the Australian National Data Service (ANDS) is to build the Australian Research Data Commons by creating the infrastructure to enable Australian researchers to easily publish, discover, access and reuse research data.</p>\n\n<p>Our approach is to engage in partnerships with research institutions to encourage better local data management, which enables structured collections to be created and information about these collections to be published via <a href=\"http://researchdata.ands.org.au/\">Research Data Australia</a>, a discovery service provided by ANDS to help researchers to find and access Australian research data. It contains descriptions of research data that is held by contributing organisations and institutions.</p>\n\n<p>ANDS involvement in the DataCite consortium ensures that we are active in global initiatives addressing the issues surrounding research data, including those of publication, citation and standards. ANDS has run its <a href=\"http://ands.org.au/services/cite-my-data.html\">Cite My Data</a> service since 2011. This service allows Australian research organisations to assign DOIs to their own research collections. This, in turn, provides researchers with a means of citing their published data and achieving recognition for their research data output.</p>\n\n<p>Subscribe to our discussion list: <a href=\"https://groups.google.com/forum/?hl=en#!forum/ands-general\">ANDS Google Group</a>.</p>\n\n<p>Subscribe to our e-newsletter: <a href=\"http://us7.campaign-archive2.com/home/?u=b542ef52e49302569068046d9&amp;id=22b849a4ee\">andsUP</a>.</p>\n\n<p>Telephone: +61 3 9902 0585<br>\nE-Mail: contact [at] ands.org.au</p>\n", "member-type"=>"allocating", "region"=>"Asia Pacific", "country"=>"Australia", "year"=>2010, "logo-url"=>"https://assets.datacite.org/images/members/ands.jpg", "email"=>nil, "website"=>"http://www.ands.org.au", "phone"=>nil, "updated"=>"2016-06-09T18:04:28.000Z"})
    end

    it "query" do
      response = subject.get_members(query: "tib")
      expect(response[:meta]).to eq("total"=>34, "member-types"=>{"allocating"=>27, "non-allocating"=>7}, "regions"=>{"amer"=>7, "apac"=>5, "emea"=>22}, "years"=>{"2015"=>5, "2014"=>4, "2013"=>4, "2012"=>1, "2011"=>1, "2010"=>9, "2009"=>7})
      member = response[:data].first
      expect(member).to eq("id"=>"tib", "type"=>"members", "attributes"=>{"title"=>"German National Library of Science and Technology (TIB)", "description"=>"", "member-type"=>"full", "region"=>"EMEA", "country"=>"Germany", "year"=>2009, "updated"=>nil})
    end
  end

  context "get_sources" do
    it "all" do
      response = subject.get_sources
      expect(response[:meta]).to eq("total"=>15, "groups"=>{"relations"=>6, "contributions"=>4, "publishers"=>2, "results"=>3})
      source = response[:data].first
      expect(source).to eq("id"=>"crossref-datacite", "type"=>"sources", "attributes"=>{"title"=>"Crossref (DataCite)", "description"=>"Import works linked to a DataCite DOI from Crossref.", "state"=>"active", "group-id"=>"relations", "work-count"=>0, "relation-count"=>0, "result-count"=>0, "by-day"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "by-month"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "updated"=>"2016-07-01T21:17:32Z"})
    end

    it "one" do
      response = subject.get_sources(id: "datacite-crossref")
      source = response[:data].first
      expect(source).to eq("id"=>"datacite-crossref", "type"=>"sources", "attributes"=>{"title"=>"DataCite (Crossref)", "description"=>"Import works with Crossref DOIs as relatedIdentifier via the DataCite Solr API.", "state"=>"active", "group-id"=>"relations", "work-count"=>0, "relation-count"=>0, "result-count"=>0, "by-day"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "by-month"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "updated"=>"2016-07-01T21:17:32Z"})
    end

    it "query" do
      response = subject.get_sources(query: "cross")
      expect(response[:meta]).to eq("total"=>3, "groups"=>{"relations"=>2, "publishers"=>1})
      source = response[:data].first
      expect(source).to eq("id"=>"crossref-datacite", "type"=>"sources", "attributes"=>{"title"=>"Crossref (DataCite)", "description"=>"Import works linked to a DataCite DOI from Crossref.", "state"=>"active", "group-id"=>"relations", "work-count"=>0, "relation-count"=>0, "result-count"=>0, "by-day"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "by-month"=>{"with-results"=>0, "without-results"=>0, "not-updated"=>0}, "updated"=>"2016-07-01T21:17:32Z"})
    end
  end

  context "get_relations" do
    it "all" do
      response = subject.get_relations
      expect(response[:meta]).to eq("total"=>7409030, "sources"=>{"datacite-related"=>6287307, "datacite-orcid"=>6, "datacite-github"=>4131, "mendeley"=>2, "github"=>386, "europe-pmc-fulltext"=>42, "datacite-crossref"=>1117156}, "relation-types"=>{"cites"=>1955, "is-cited-by"=>1364, "is-supplement-to"=>489039, "is-supplemented-by"=>489041, "continues"=>157600, "is-continued-by"=>157594, "is-metadata-for"=>194, "has-metadata"=>194, "is-part-of"=>278859, "has-part"=>280309, "references"=>2560253, "is-referenced-by"=>2560314, "documents"=>1799, "is-documented-by"=>1781, "compiles"=>43, "reviews"=>1174, "is-reviewed-by"=>1174, "is-derived-from"=>34725, "is-source-of"=>35211, "bookmarks"=>111, "is-new-version-of"=>100790, "is-previous-version-of"=>100767, "is-original-form-of"=>3537, "is-variant-form-of"=>2987, "is-identical-to"=>148074, "is-compiled-by"=>43, "is-bookmarked-by"=>98})
      relation = response[:data].first
      expect(relation).to eq("id"=>"8a9c5431-5557-4189-8b0c-98c0b7d4b72f", "type"=>"relations", "attributes"=>{"subj-id"=>"http://doi.org/10.5194/CP-12-171-2016", "obj-id"=>"http://doi.org/10.1594/PANGAEA.849156", "doi"=>"10.5194/CP-12-171-2016", "author"=>[], "title"=>"Spatial and temporal oxygen isotope variability in northern Greenland – implications for a new climate record over the past millennium", "container-title"=>nil, "source-id"=>"datacite-crossref", "publisher-id"=>"3145", "registration-agency-id"=>"crossref", "relation-type-id"=>"is-referenced-by", "type"=>nil, "total"=>1, "published"=>"2016-02-03", "issued"=>"2016-02-03T00:00:00Z", "updated"=>"2016-05-28T10:10:26Z"})
    end

    it "by work" do
      response = subject.get_relations("work-id" => "10.6084/M9.FIGSHARE.3394312")
      expect(response[:meta]).to eq("total"=>1, "sources"=>{"datacite-related"=>1}, "relation-types"=>{"is-identical-to"=>1})
      relation = response[:data].first
      expect(relation).to eq("id"=>"a139f108-622a-4c8a-9622-9401cc82c6df", "type"=>"relations", "attributes"=>{"subj-id"=>"http://doi.org/10.6084/M9.FIGSHARE.3394312.V1", "obj-id"=>"http://doi.org/10.6084/M9.FIGSHARE.3394312", "doi"=>"10.6084/M9.FIGSHARE.3394312.V1", "author"=>[{"given"=>"Samuel", "family"=>"Asumadu-Sarkodie", "orcid"=>"http://orcid.org/0000-0001-5035-5983"}, {"given"=>"Phebe Asantewaa", "family"=>"Owusu", "orcid"=>"http://orcid.org/0000-0001-7364-1640"}], "title"=>"Global Annual Installations 2000-2013", "container-title"=>"Figshare", "source-id"=>"datacite-related", "publisher-id"=>"CDL.DIGSCI", "registration-agency-id"=>nil, "relation-type-id"=>"is-identical-to", "type"=>nil, "total"=>1, "published"=>"2016", "issued"=>"2016-05-20T20:40:22Z", "updated"=>"2016-06-01T20:01:21Z"})
    end
  end

  context "get_contributions" do
    it "all" do
      response = subject.get_contributions
      expect(response[:meta]).to eq("total"=>1071843, "sources"=>{"datacite-related"=>6639, "datacite-orcid"=>1061078, "github-contributor"=>492, "datacite-search-link"=>3634})
      contribution = response[:data].first
      expect(contribution).to eq("id"=>"cd37482b-af89-428f-8d78-f66c9daa5e77", "type"=>"contributions", "attributes"=>{"doi"=>"10.13140/2.1.4110.8481", "credit-name"=>"José Amendoeira", "orcid"=>"0000-0002-4464-8517", "author"=>[{"family"=>"Seabra", "given"=>"Paulo"}, {"family"=>"Santos", "given"=>"Alexandra"}, {"family"=>"Garcia", "given"=>"Lurdes"}, {"family"=>"Amendoeira", "given"=>"José"}, {"family"=>"Sá", "given"=>"Luís"}], "title"=>"Drug addiction", "container-title"=>"Unpublished", "source-id"=>"datacite-search-link", "contributor-role-id"=>"contribution", "type"=>nil, "published"=>"2012", "issued"=>"2014-10-29T21:16:03Z", "updated"=>"2016-05-29T12:12:26Z"})
    end

    it "by contributor" do
      response = subject.get_contributions("contributor-id" => "orcid.org/0000-0002-8635-8390")
      expect(response[:meta]).to eq("total"=>162093, "sources"=>{"datacite-related"=>359, "datacite-orcid"=>161721, "datacite-search-link"=>13})
      contribution = response[:data].first
      expect(contribution).to eq("id"=>"8ea09e4d-e3f9-4b0e-814f-4941f7b0179e", "type"=>"contributions", "attributes"=>{"doi"=>"10.6084/M9.FIGSHARE.1126238", "credit-name"=>"Henry Rzepa", "orcid"=>"0000-0002-8635-8390", "author"=>[{"given"=>"Henry S.", "family"=>"Rzepa", "orcid"=>"http://orcid.org/0000-0002-8635-8390"}], "title"=>"Gaussian Job Archive for C50H66N6O2", "container-title"=>"Figshare", "source-id"=>"datacite-orcid", "contributor-role-id"=>"contribution", "type"=>nil, "published"=>"2014", "issued"=>"2014-08-08T15:31:07Z", "updated"=>"2016-05-28T07:41:10Z"})
    end
  end
end
