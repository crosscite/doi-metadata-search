require 'spec_helper'

describe 'search', type: :feature, js: true, vcr: true do
  it '/repositories?query=university' do
    visit '/repositories?query=university'
    expect(page).to have_css("h3.results", text: "350 Repositories")
  end
end
