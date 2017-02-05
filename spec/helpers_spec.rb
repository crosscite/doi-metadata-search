require 'spec_helper'

describe "Helpers", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "license_img" do
    it "understands CC Zero" do
      license = "https://creativecommons.org/publicdomain/zero/1.0/"
      expect(subject.license_img(license)).to eq("https://licensebuttons.net/p/zero/1.0/80x15.png")
    end
  end

  context "validate_orcid" do
    it "validate_orcid" do
      orcid = "http://orcid.org/0000-0002-2590-225X"
      response = subject.validate_orcid(orcid)
      expect(response).to eq("0000-0002-2590-225X")
    end

    it "validate_orcid id" do
      orcid = "0000-0002-2590-225X"
      response = subject.validate_orcid(orcid)
      expect(response).to eq("0000-0002-2590-225X")
    end

    it "validate_orcid wrong id" do
      orcid = "0000 0002 1394 3097"
      response = subject.validate_orcid(orcid)
      expect(response).to be_nil
    end
  end

  context "validate_doi" do
    it "validate_doi" do
      doi = "https://doi.org/10.6084/M9.FIGSHARE.3501629"
      response = subject.validate_doi(doi)
      expect(response).to eq("10.6084/M9.FIGSHARE.3501629")
    end

    it "validate_doi http" do
      doi = "http://doi.org/10.6084/M9.FIGSHARE.3501629"
      response = subject.validate_doi(doi)
      expect(response).to eq("10.6084/M9.FIGSHARE.3501629")
    end

    it "validate_doi id" do
      doi = "10.6084/M9.FIGSHARE.3501629"
      response = subject.validate_doi(doi)
      expect(response).to eq("10.6084/M9.FIGSHARE.3501629")
    end

    it "validate_doi wrong id" do
      doi = "10.abc/M9.FIGSHARE.3501629"
      response = subject.validate_doi(doi)
      expect(response).to be_nil
    end
  end

  context "helpers" do
    it "relation_type_title" do
      related_identifiers = [{ "relation-type-id" => "HasPart",
                               "related-identifier" => "https://doi.org/10.5061/DRYAD.T748P/1" }]
      id = "https://doi.org/10.5061/DRYAD.T748P/1"
      response = subject.relation_type_title(related_identifiers, id)
      expect(response).to eq("Is part of")
    end
  end
end
