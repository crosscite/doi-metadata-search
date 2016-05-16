require 'spec_helper'

describe "API", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "get_works" do
    it "all" do
      response = subject.get_works
      expect(response[:meta]).to eq("total"=>20)
      work = response[:data].first
      expect(work).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "updated-at"=>"1970-01-01T00:00:00Z"})
    end

    it "one" do
      response = subject.get_works(id: "orcid.org/0000-0002-4000-4167")
      work = response[:data]
      expect(work).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "updated-at"=>"1970-01-01T00:00:00Z"})
    end

    it "query" do
      response = subject.get_works(q: "mabbett")
      expect(response[:meta]).to eq("total"=>1)
      work = response[:data].first
      expect(work).to eq("id"=>"http://orcid.org/0000-0001-5882-6823", "type"=>"contributors", "attributes"=>{"given"=>"Andy", "family"=>"Mabbett", "updated-at"=>"1970-01-01T00:00:00Z"})
    end
  end

  context "get_contributors" do
    it "all" do
      response = subject.get_contributors
      expect(response[:meta]).to eq("total"=>20)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "updated-at"=>"1970-01-01T00:00:00Z"})
    end

    it "one" do
      response = subject.get_contributors(id: "orcid.org/0000-0002-4000-4167")
      contributor = response[:data]
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0002-4000-4167", "type"=>"contributors", "attributes"=>{"given"=>"Peter", "family"=>"Arend", "updated-at"=>"1970-01-01T00:00:00Z"})
    end

    it "query" do
      response = subject.get_contributors(q: "mabbett")
      expect(response[:meta]).to eq("total"=>1)
      contributor = response[:data].first
      expect(contributor).to eq("id"=>"http://orcid.org/0000-0001-5882-6823", "type"=>"contributors", "attributes"=>{"given"=>"Andy", "family"=>"Mabbett", "updated-at"=>"1970-01-01T00:00:00Z"})
    end
  end

  context "get_datacenters" do
    it "all" do
      response = subject.get_datacenters
      expect(response[:meta]).to eq("total"=>713, "total-pages"=>29, "page"=>1, "registration-agencies"=>{"datacite"=>713})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"ETHZ.UBASOJS", "type"=>"publishers", "attributes"=>{"title"=>"027.7 - Zeitschrift für Bibliothekskultur", "other-names"=>[], "prefixes"=>[], "member-id"=>"ETHZ", "registration-agency-id"=>"datacite", "updated-at"=>"2016-05-11T17:06:12Z"})
    end

    it "one" do
      response = subject.get_datacenters(id: "CERN.ZENODO")
      datacenter = response[:data]
      expect(datacenter).to eq("id"=>"CERN.ZENODO", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"CERN", "registration-agency-id"=>"datacite", "updated-at"=>"2016-05-11T17:10:46Z"})
    end

    it "query" do
      response = subject.get_datacenters(q: "zeno")
      expect(response[:meta]).to eq("total"=>1, "total-pages"=>1, "page"=>1, "registration-agencies"=>{"datacite"=>1})
      datacenter = response[:data].first
      expect(datacenter).to eq("id"=>"CERN.ZENODO", "type"=>"publishers", "attributes"=>{"title"=>"ZENODO - Research. Shared.", "other-names"=>[], "prefixes"=>[], "member-id"=>"CERN", "registration-agency-id"=>"datacite", "updated-at"=>"2016-05-11T17:10:46Z"})
    end
  end

  context "get_members" do
    it "all" do
      response = subject.get_members
      expect(response[:meta]).to eq("total"=>2, "member-types"=>{"full"=>2}, "regions"=>{"apac"=>1, "emea"=>1}, "years"=>{"2010"=>1, "2009"=>1})
      member = response[:data].first
      expect(member).to eq("id"=>"ANDS", "type"=>"members", "attributes"=>{"title"=>"ANDS", "description"=>"<p>CSIC  will run its <a href=\"http://ands.org.au/services/cite-my-data.html\">Cite My Data</a> service since 2016. This service allows CSIC’s researcher  to assign DOIs to their own research datasets providing researchers with a means of citing their published data and achieving recognition for their research data output.</p>\n", "member-type"=>"full", "region"=>"Asia Pacific", "country"=>"Australia", "year"=>2010})
    end

    it "one" do
      response = subject.get_members(id: "ANDS")
      member = response[:data]
      expect(member).to eq("id"=>"ANDS", "type"=>"members", "attributes"=>{"title"=>"ANDS", "description"=>"<p>CSIC  will run its <a href=\"http://ands.org.au/services/cite-my-data.html\">Cite My Data</a> service since 2016. This service allows CSIC’s researcher  to assign DOIs to their own research datasets providing researchers with a means of citing their published data and achieving recognition for their research data output.</p>\n", "member-type"=>"full", "region"=>"Asia Pacific", "country"=>"Australia", "year"=>2010})
    end

    it "query" do
      response = subject.get_members(q: "tib")
      expect(response[:meta]).to eq("total"=>1, "member-types"=>{"full"=>1}, "regions"=>{"emea"=>1}, "years"=>{"2009"=>1})
      member = response[:data].first
      expect(member).to eq("id"=>"TIB", "type"=>"members", "attributes"=>{"title"=>"German National Library of Science and Technology (TIB)", "description"=>"", "member-type"=>"full", "region"=>"EMEA", "country"=>"Germany", "year"=>2009})
    end
  end
end
