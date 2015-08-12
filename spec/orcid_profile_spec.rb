require 'spec_helper'

describe OrcidProfile, :type => :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }
  let(:response) { File.read(fixture_path + 'orcid_profile.json') }

  subject { OrcidProfile.new(response) }

  it 'version' do
    expect(subject.version).to eq("1.2")
  end

  it 'uid' do
    expect(subject.uid).to eq("0000-0001-6528-2027")
  end

  it 'dois' do
    expect(subject.dois).to eq(["10.5281/ZENODO.21429", "10.5061/DRYAD.R98G7", "10.5167/UZH-92715", "10.6084/M9.FIGSHARE.706340", "10.6084/M9.FIGSHARE.154691", "10.5167/UZH-81963", "10.6084/M9.FIGSHARE.821213", "10.3205/12AGMB03", "10.6084/M9.FIGSHARE.90828", "10.6084/M9.FIGSHARE.90829", "10.5066/F7862DCT", "10.5167/UZH-19531", "10.5517/CCNDSMF", "10.3932/ETHZ-A-000130313", "10.5169/SEALS-118645", "10.5169/SEALS-355044"])
  end
end
