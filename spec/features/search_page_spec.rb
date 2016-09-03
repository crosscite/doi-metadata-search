require 'spec_helper'

describe 'search', type: :feature, js: true, vcr: true do
  it '/' do
    visit '/'
    expect(page).to have_css '#query'
  end

  # it 'input' do
  #   visit '/'
  #   fill_in 'search-input', with: 'climate'
  #   click_button 'submit'

  #   expect(page).to have_css 'h4.results'
  # end

  # it 'search' do
  #   visit '/works?query=climate'
  #   expect(page).to have_field 'search-input', with: 'climate'
  #   expect(page).to have_css 'h4.results'
  # end
end
