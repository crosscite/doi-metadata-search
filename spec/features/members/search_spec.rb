require 'spec_helper'

describe 'search', type: :feature, js: true, vcr: true do
  it '/members?query=university' do
    visit '/members?query=university'
    expect(page).to have_css("h3.results", text: "106 Members")
  end
end
