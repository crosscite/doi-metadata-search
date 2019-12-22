require 'spec_helper'

describe 'citation', type: :feature, js: true, vcr: true do
  it 'no citation information' do
    visit '/works/10.0311/fk2/e11643a99d903d0ccfc2d523b344d9ff'

    expect(page).to have_css("#summary-citations", text: "No citations were reported. No usage information was reported.")
  end

  # it 'show summary information list view' do
  #   visit '/works?query=dufek+AND+intrusion'

  #   expect(page).to have_css("#summary-citations", text: "4 citations")
  #   expect(page).to have_css("#summary-views", text: "No usage information was reported.")
  # end

  # it 'show summary information' do
  #   visit '/works/10.91819/71718'

  #   expect(page).to have_css("#summary-citations", text: "4 citations")
  #   expect(page).to have_css("#summary-views", text: "No usage information was reported.")
  # end

  # it 'show citation chart' do
  #   visit '/works/10.91819/71718'

  #   expect(page).to have_css("#citations-tab", text: "4 Citations")
  #   expect(page).to have_css("small", text: "4 citations reported since publication in 2011.")
  #   expect(page).to have_css("svg", count: 1)
  # end
end
