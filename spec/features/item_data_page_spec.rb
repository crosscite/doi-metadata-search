require 'spec_helper'

describe 'item', type: :feature, js: true, vcr: true do
  it '/works?query=climate' do
    visit '/works?query=climate'
    expect(page).to have_css 'h4.results'
  end
end
