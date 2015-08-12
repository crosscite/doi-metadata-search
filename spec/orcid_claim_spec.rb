require 'spec_helper'

describe OrcidClaim, :type => :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:work) { { "doi_key" => "10.5061/DRYAD.781PV",
                 "creator" => ["Piwowar, Heather A.", "Vision, Todd J."],
                 "title" => "Data from: Data reuse and the open data citation advantage",
                 "publisher" => "Dryad Digital Repository",
                 "publicationYear" => "2013" } }

  subject { OrcidClaim.new(work) }

  it 'doi' do
    expect(subject.doi).to eq("10.5061/DRYAD.781PV")
  end

  it 'url' do
    expect(subject.url).to eq("http://doi.org/10.5061/DRYAD.781PV")
  end

  it 'contributors' do
    expect(subject.contributors).to eq([{:orcid=>nil, :credit_name=>"Piwowar, Heather A.", :role=>nil},
                                        {:orcid=>nil, :credit_name=>"Vision, Todd J.", :role=>nil}])
  end

  it 'title' do
    expect(subject.title).to eq("Data from: Data reuse and the open data citation advantage")
  end

  it 'publisher' do
    expect(subject.publisher).to eq("Dryad Digital Repository")
  end

  it 'publication_year' do
    expect(subject.publication_year).to eq("2013")
  end

  context 'to_xml' do

    it 'initialize' do
      xml = File.read(fixture_path + 'orcid_claim.xml')
      expect(subject.to_xml).to eq(xml)
    end
  end
end
