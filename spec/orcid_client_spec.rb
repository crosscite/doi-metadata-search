require 'spec_helper'

describe OrcidClient, type: :model, vcr: true do

  let(:session_info) { OmniAuth.config.mock_auth[:orcid]  }

  subject { OrcidClient.new(session_info) }

  it 'new' do
    expect(subject.uid).to eq("0000-0002-1825-0097")
  end

  # it 'get' do
  #   expect(subject.get).to eq("10.5061/DRYAD.781PV")
  # end

  # it 'get invalid token' do
  #   session_info = { uid: '0000-0001-6528-2027', 'credentials' => { 'token' => '123' } }
  #   expect(subject.get).to eq("10.5061/DRYAD.781PV")
  # end
end
