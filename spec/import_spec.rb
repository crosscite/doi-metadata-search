require 'spec_helper'

describe Import, type: :model, vcr: true do
  before(:each) { allow(Time).to receive(:now).and_return(Time.mktime(2015, 4, 8)) }
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { Import.new }

  context "get_query_url" do
    it "default" do
      expect(subject.get_query_url).to eq("http://search.datacite.org/api?q=nameIdentifier%3AORCID%5C%3A*&start=0&rows=1000&fl=doi%2CnameIdentifier%2Cupdated&fq=updated%3A%5B2015-04-07T00%3A00%3A00Z+TO+2015-04-08T23%3A59%3A59Z%5D+AND+has_metadata%3Atrue+AND+is_active%3Atrue&wt=json")
    end

    it "with zero rows" do
      expect(subject.get_query_url(rows: 0)).to eq("http://search.datacite.org/api?q=nameIdentifier%3AORCID%5C%3A*&start=0&rows=1000&fl=doi%2CnameIdentifier%2Cupdated&fq=updated%3A%5B2015-04-07T00%3A00%3A00Z+TO+2015-04-08T23%3A59%3A59Z%5D+AND+has_metadata%3Atrue+AND+is_active%3Atrue&wt=json")
    end

    it "with different from_date and until_date" do
      expect(subject.get_query_url(from_date: "2015-04-05", until_date: "2015-04-05")).to eq("http://search.datacite.org/api?q=nameIdentifier%3AORCID%5C%3A*&start=0&rows=1000&fl=doi%2CnameIdentifier%2Cupdated&fq=updated%3A%5B2015-04-07T00%3A00%3A00Z+TO+2015-04-08T23%3A59%3A59Z%5D+AND+has_metadata%3Atrue+AND+is_active%3Atrue&wt=json")
    end

    it "with offset" do
      expect(subject.get_query_url(offset: 250)).to eq("http://search.datacite.org/api?q=nameIdentifier%3AORCID%5C%3A*&start=0&rows=1000&fl=doi%2CnameIdentifier%2Cupdated&fq=updated%3A%5B2015-04-07T00%3A00%3A00Z+TO+2015-04-08T23%3A59%3A59Z%5D+AND+has_metadata%3Atrue+AND+is_active%3Atrue&wt=json")
    end

    it "with rows" do
      expect(subject.get_query_url(rows: 250)).to eq("http://search.datacite.org/api?q=nameIdentifier%3AORCID%5C%3A*&start=0&rows=1000&fl=doi%2CnameIdentifier%2Cupdated&fq=updated%3A%5B2015-04-07T00%3A00%3A00Z+TO+2015-04-08T23%3A59%3A59Z%5D+AND+has_metadata%3Atrue+AND+is_active%3Atrue&wt=json")
    end
  end

  context "get_total" do
    it "with works" do
      expect(subject.get_total).to eq(62
      )
    end

    it "with no works" do
      expect(subject.get_total(from_date: "2009-04-07", until_date: "2009-04-08")).to eq(0)
    end
  end

  context "queue_jobs" do
    it "should report if there are no works returned by the Datacite Metadata Search API" do
      response = subject.queue_jobs(from_date: "2009-04-07", until_date: "2009-04-08")
      expect(response).to eq(0)
    end

    it "should report if there are works returned by the Datacite Metadata Search API" do
      response = subject.queue_jobs
      expect(response).to eq(62)
    end
  end

  context "get_data" do
    it "should report if there are no works returned by the Datacite Metadata Search API" do
      response = subject.get_data(from_date: "2009-04-07", until_date: "2009-04-08")
      expect(response["response"]["numFound"]).to eq(0)
    end

    it "should report if there are works returned by the Datacite Metadata Search API" do
      response = subject.get_data
      expect(response["response"]["numFound"]).to eq(62)
      doc = response["response"]["docs"].first
      expect(doc["doi"]).to eq("10.1594/PANGAEA.733793")
    end

    it "should catch errors with the Datacite Metadata Search API" do
      stub = stub_request(:get, subject.get_query_url(rows: 0)).to_return(:status => [408])
      response = subject.get_data(rows: 0)
      expect(response).to eq(error: "the server responded with status 408 for http://search.datacite.org/api?q=nameIdentifier%3AORCID%5C%3A*&start=0&rows=0&fl=doi%2Ccreator%2Ctitle%2Cpublisher%2CpublicationYear%2CresourceTypeGeneral%2Cdatacentre_symbol%2CnameIdentifier%2Cxml%2Cupdated&fq=updated%3A%5B2015-04-07T00%3A00%3A00Z+TO+2015-04-08T23%3A59%3A59Z%5D+AND+has_metadata%3Atrue+AND+is_active%3Atrue&wt=json", :status=>408)
      expect(stub).to have_been_requested
    end
  end

  context "parse_data" do
    it "should report if there are no works returned by the Datacite Metadata Search API" do
      body = File.read(fixture_path + 'datacite_import_nil.json')
      result = JSON.parse(body)
      expect(subject.parse_data(result, nil)).to be_empty
    end

    it "should report if there are works returned by the Datacite Metadata Search API" do
      body = File.read(fixture_path + 'datacite_import.json')
      result = JSON.parse(body)
      response = subject.parse_data(result, nil)

      expect(response.length).to eq(63)
      work = response.first
      expect(work).to eq(:orcid=>"0000-0002-4133-2218", :doi=>"10.1594/PANGAEA.733793")
    end
  end
end
