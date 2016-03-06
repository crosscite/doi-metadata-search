require 'spec_helper'

describe SearchResult do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:solr_doc) { { "doi" => "10.5061/dryad.f1cb2" } }
  let(:solr_result) { ::ActiveSupport::JSON.decode(File.read(fixture_path + 'solr_response.json')) }
  let(:user_state) { {} }
  let(:related_identifiers) { {} }

  subject { SearchResult.new(solr_doc, solr_result, user_state, related_identifiers) }

  context "search_results" do
    it "no result" do
      solr_result = { "doi" => "10.5061/dryad.f1cb2" }
      response = subject.search_results(solr_result)
      expect(response).to be_empty
    end
  end
end
