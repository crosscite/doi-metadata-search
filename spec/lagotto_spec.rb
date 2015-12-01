require 'spec_helper'

describe OrcidClaim, type: :model, vcr: true do
  subject { OrcidClaim.new(nil) }

  let(:doi) { "10.5061/dryad.f1cb2" }
  let(:dois) { ["10.5061/dryad.df3sn","10.5061/dryad.f1cb2"] }

  context "dois_as_string" do
    it "get single doi" do
      response = subject.dois_as_string([doi])
      expect(response).to eq("work_ids=http://doi.org/10.5061/dryad.f1cb2")
    end

    it "get multiple dois" do
      response = subject.dois_as_string(dois)
      expect(response).to eq("work_ids=http://doi.org/10.5061/dryad.df3sn,http://doi.org/10.5061/dryad.f1cb2")
    end
  end

  context "get_references" do
    it "get single doi" do
      response = subject.get_references([doi])
      references = response.fetch(doi.upcase, [])
      expect(references.length).to eq(6)
      expect(references.first).to eq(:doi=>"10.5061/DRYAD.F1CB2", :relation=>"IsCitedBy", :id=>"DOI", :text=>"10.1073/PNAS.1205856110", :source=>"Europe PMC")
    end

    it "get multiple dois" do
      response = subject.get_references(dois)
      references = response.fetch(dois.last.upcase, [])
      expect(references.length).to eq(6)
      expect(references.first).to eq(:doi=>"10.5061/DRYAD.F1CB2", :relation=>"IsCitedBy", :id=>"DOI", :text=>"10.1073/PNAS.1205856110", :source=>"Europe PMC")
    end

    it "get no doi" do
      response = subject.get_references([])
      references = response.fetch(doi, [])
      expect(references.length).to be_empty
    end
  end
end
