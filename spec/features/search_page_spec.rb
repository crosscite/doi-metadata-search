require 'spec_helper'

describe 'search', type: :feature, js: true, vcr: true do
  it '/' do
    visit '/'
    expect(page).to have_css '#search-input'
  end

  it 'input' do
    visit '/'
    fill_in 'search-input', with: 'climate'
    find('#search-input').native.send_key(:Enter)

    expect(page).to have_css '.item-list'
  end

  it 'search' do
    visit '/?q=climate'
    expect(page).to have_field 'search-input', with: 'climate'
    expect(page).to have_css '.item-list'
  end

  it 'match doi' do
    visit '/?q=10.6084%2FM9.FIGSHARE.154691'
    expect(page).to have_field 'search-input', with: '10.6084/M9.FIGSHARE.154691'
    expect(page).to have_css '.alert-info', text: "Showing DOI matching 10.6084/m9.figshare.154691"
    expect(page).to have_css '.item-list'
  end

  it 'match short doi' do
    visit '/?q=10/kz6'
    expect(page).to have_field 'search-input', with: '10/kz6'
    expect(page).to have_css '.alert-info', text: "Resolved short DOI to 10.6084/M9.FIGSHARE.154691"
    expect(page).to have_css '.item-list'
  end

  it 'match urn' do
    visit '/?q=urn:nbn:de:tib-10.1594/WDCC/MB_HEF_1953-20104'
    expect(page).to have_field 'search-input', with: 'urn:nbn:de:tib-10.1594/WDCC/MB_HEF_1953-20104'
    expect(page).to have_css '.alert-info', text: "Showing URN matching urn:nbn:de:tib-10.1594/WDCC/MB_HEF_1953-20104"
    expect(page).to have_css '.item-list'
  end

  it 'match orcid' do
    visit '/?q=0000-0003-1613-5981'
    expect(page).to have_field 'search-input', with: '0000-0003-1613-5981'
    expect(page).to have_css '.alert-info', text: "Showing results for ORCID matching 0000-0003-1613-5981"
    expect(page).to have_css '.item-list'
  end



end
