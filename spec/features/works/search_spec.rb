require 'spec_helper'

describe 'search', type: :feature, js: true, vcr: true do
  it '/' do
    visit '/'
    expect(page).to have_css '#query'
  end

  it 'input' do
    visit "/"
    fill_in "query", with: "climate"
    click_button "Search"

    expect(page).to have_css "h3.results"
  end

  it 'search' do
    visit "/works?query=climate"
    expect(page).to have_field "query", with: "climate"
    expect(page).to have_css("h3.results", text: "3,538 Works")
  end
end
