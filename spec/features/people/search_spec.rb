require 'spec_helper'

describe 'search', type: :feature, js: true, vcr: true do
  it '/people?query=smith' do
    visit '/people?query=smith'
    expect(page).to have_css("h3.results", text: "136 People")
  end
end
