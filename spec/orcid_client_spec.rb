require 'spec_helper'

describe OrcidClient, :type => :model, vcr: true do
  let(:session_info) { { uid: '0000-0001-6528-2027',
                         'credentials' => { 'token' => '123' } } }

  subject { OrcidClient.new(session_info) }

  it 'new' do
    expect(subject.uid).to eq("10.5061/DRYAD.781PV")
  end

  it 'get' do
    expect(subject.get).to eq("10.5061/DRYAD.781PV")
  end
end
