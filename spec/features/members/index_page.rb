require 'spec_helper'

describe 'index', type: :feature, js: true, vcr: true do
  it '/members?query=tib' do
    visit '/members=tib'
    expect(page).to have_css 'h1.results'
  end
end
