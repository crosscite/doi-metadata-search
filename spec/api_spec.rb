require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]).to eq("resource-types"=>{"dataset"=>2472320, "other"=>870532, "text"=>835718, "image"=>686490, "collection"=>310244, "physical-object"=>34335, "software"=>13428, "event"=>6455, "audiovisual"=>5216, "film"=>965, "model"=>533, "interactive-resource"=>294, "sound"=>235, "workflow"=>209, "service"=>19}, "years"=>{}, "publishers"=>{}, "total"=>6549181)
      work = response[:data].first
      expect(work).to eq("id"=>"http://doi.org/10.3932/ETHZ-A-000365332", "type"=>"works", "attributes"=>{"author"=>[], "title"=>nil, "container-title"=>nil, "description"=>nil, "published"=>nil, "issued"=>"2016-05-24T17:33:01Z", "updated"=>nil, "doi"=>"10.3932/ETHZ-A-000365332", "resource-type-general"=>nil, "resource-type"=>nil, "type"=>nil, "license"=>nil, "publisher-id"=>"ethz.unknown"})
    end

    it "one" do
      response = subject.get_works(id: "10.6084/M9.FIGSHARE.C.1909847")
      work = response[:data]
      expect(work).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "updated-at"=>"1970-01-01T00:00:00Z"})
    end

    it "query" do
      response = subject.get_works(q: "mabbett")
      expect(response[:meta]).to eq("resource-types"=>{"dataset"=>15, "text"=>1}, "years"=>{}, "publishers"=>{}, "total"=>16)
      work = response[:data].first
      expect(work).to eq("id"=>"http://doi.org/10.6084/M9.FIGSHARE.1419601", "type"=>"works", "attributes"=>{"author"=>[{"family"=>"Mabbett", "given"=>"Andy", "orcid"=>"http://orcid.org/0000-0001-5882-6823"}], "title"=>"2015-05-13 - Authority control in Wikipedia - Qatar", "container-title"=>"Figshare", "description"=>nil, "published"=>"2015", "issued"=>"2015-05-19T15:57:08Z", "updated"=>"2015-05-19T15:57:08Z", "doi"=>"10.6084/M9.FIGSHARE.1419601", "resource-type-general"=>"dataset", "resource-type"=>"Presentation", "type"=>nil, "license"=>"http://creativecommons.org/licenses/by/3.0/us/", "publisher-id"=>"cdl.digsci"})
    end
  end

  context "get_contributors" do
    it "all" do
      response = subject.get_contributors
      expect(response[:meta]).to eq("total"=>5616)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"https://github.com/mne-tools", "type"=>"contributors", "attributes"=>{"given"=>nil, "family"=>nil, "updated"=>"1970-01-01T00:00:00Z"})
    end

    it "one" do
      response = subject.get_contributors(id: "orcid.org/0000-0002-4000-4167")
      contributor = response[:data]
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "updated"=>"1970-01-01T00:00:00Z"})
    end

    it "query" do
      response = subject.get_contributors(q: "mabbett")
      expect(response[:meta]).to eq("total"=>1)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0001-5882-6823", "type"=>"contributors", "attributes"=>{"given"=>"Andy", "family"=>"Mabbett", "updated"=>"1970-01-01T00:00:00Z"})
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      expect(response[:meta]).to eq("total"=>721, "total-pages"=>29, "page"=>1, "registration-agencies"=>{"datacite"=>721})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"ethz.ubasojs", "type"=>"publishers", "attributes"=>{"title"=>"027.7 - Zeitschrift für Bibliothekskultur", "other-names"=>[], "prefixes"=>[], "member-id"=>"ethz", "registration-agency-id"=>"datacite", "updated"=>"2016-05-25T10:48:13Z"})
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenter = response[:data]
      expect(datacenter).to eq("id"=>"cern.zenodo", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"cern", "registration-agency-id"=>"datacite", "updated"=>"2016-05-25T11:45:25Z"})
    end

    it "query" do
      response = subject.get_datacenters(q: "zeno")
      expect(response[:meta]).to eq("total"=>1, "total-pages"=>1, "page"=>1, "registration-agencies"=>{"datacite"=>1})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"cern.zenodo", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"cern", "registration-agency-id"=>"datacite", "updated"=>"2016-05-25T11:45:25Z"})
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
end
