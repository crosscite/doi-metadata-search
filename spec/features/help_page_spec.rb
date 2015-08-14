require 'spec_helper'

describe "help", type: :feature, js: true do
  it 'examples' do
    visit '/help/examples'
    expect(page).to have_css "h2", "Examples"
  end

  it 'status' do
    visit '/help/stats'
    expect(page).to have_css "h2", "Stats"
  end
end
