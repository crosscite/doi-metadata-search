require 'spec_helper'

describe User, type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:solr_doc) { { "doi" => "10.5061/dryad.f1cb2" } }
  let(:solr_result) { ::ActiveSupport::JSON.decode(File.read(fixture_path + 'solr_response.json')) }
  let(:user_state) { {} }
  let(:related_identifiers) { {} }

  let(:doi) { "10.5517/CC1JZZ2K" }
  let(:dois) { ["10.1594/PANGAEA.845725","10.5517/CC1JZZ2K"] }

  subject { SearchResult.new(solr_doc, solr_result, user_state, related_identifiers) }

  context "dois_as_string" do
    it "get single doi" do
      response = subject.dois_as_string([doi])
      expect(response).to eq("work_ids=http://doi.org/10.5517/CC1JZZ2K")
    end

    it "get multiple dois" do
      response = subject.dois_as_string(dois)
      expect(response).to eq("work_ids=http://doi.org/10.1594/PANGAEA.845725,http://doi.org/10.5517/CC1JZZ2K")
    end
  end

  context "get_relations" do
    it "get single doi" do
      response = subject.get_relations([doi])
      relations = response.fetch(doi.upcase, [])
      expect(relations.length).to eq(1)
      expect(relations.first).to eq(doi: "10.5517/CC1JZZ2K",
                                    id: "http://doi.org/10.1016/j.ica.2016.02.005",
                                    relation: "IsSupplementTo",
                                    source: "DataCite",
                                    title: "A dinuclear iron(II) complex bearing multidentate pyridinyl ligand: Synthesis, characterization and its catalysis on the hydroxylation of aromatic compounds",
                                    container_title: nil,
                                    author: [],
                                    issued: {"date-parts"=>[[2016, 2, 14]]})
    end

    it "get multiple dois" do
      response = subject.get_relations(dois)
      expect(response.keys).to eq(["10.5517/CC1JZZ2K", "10.1594/PANGAEA.845725"])
      relations = response.fetch(dois.first.upcase, [])
      expect(relations.first).to eq(doi: "10.1594/PANGAEA.845725",
                                    id: "http://doi.org/10.5194/essd-2015-38",
                                    relation: "IsSupplementTo",
                                    source: "DataCite",
                                    title: "Observational gridded runoff estimates for Europe (E-RUN version 1.0)",
                                    container_title: nil,
                                    author: [],
                                    issued: {"date-parts"=>[[2016, 1, 18]]})
    end

    it "get no doi" do
      response = subject.get_relations([])
      expect(response).to be_empty
    end
  end
end
