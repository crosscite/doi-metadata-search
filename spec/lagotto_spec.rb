require 'spec_helper'

describe "Lagotto", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:solr_doc) { { "doi" => "10.5061/dryad.f1cb2" } }
  let(:solr_result) { ::ActiveSupport::JSON.decode(File.read(fixture_path + 'solr_response.json')) }
  let(:claimed) { false }
  let(:related_identifiers) { {} }

  let(:doi) { "10.17600/14000300" }
  let(:dois) { ["10.15468/DIPJCR","10.17600/14000300"] }

  subject { SearchResult.new(solr_doc, solr_result, claimed, related_identifiers) }

  context "work_ids_as_string" do
    it "get single doi" do
      response = subject.ids_as_string([doi])
      expect(response).to eq("ids=10.17600/14000300")
    end

    it "get multiple dois" do
      response = subject.ids_as_string(dois)
      expect(response).to eq("ids=10.15468/DIPJCR,10.17600/14000300")
    end
  end

  context "get_relations" do
    it "get single doi" do
      response = subject.get_relations([doi])
      relations = response.fetch(doi.upcase, [])
      expect(relations.length).to eq(1)
      expect(relations.first).to eq(:doi=>"10.17600/14000300", :signposts=>[{"title"=>"DataCite (RelatedIdentifier)",
                                                                            "count"=>1,
                                                                            "name"=>"datacite_related"}])
    end

    it "get multiple dois" do
      response = subject.get_relations(dois)
      expect(response.keys).to eq(["10.15468/DIPJCR", "10.17600/14000300"])
      relations = response.fetch(dois.first.upcase, [])
      expect(relations.first).to eq(:doi=>"10.15468/DIPJCR", :signposts=>[{"title"=>"DataCite (RelatedIdentifier)",
                                                                           "count"=>1002,
                                                                           "name"=>"datacite_related"}])
    end

    it "get no doi" do
      response = subject.get_relations([])
      expect(response).to be_empty
    end
  end
end
