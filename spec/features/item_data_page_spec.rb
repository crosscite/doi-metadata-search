require 'spec_helper'

describe 'item', type: :feature, js: true, vcr: true do
  it '/?q=climate' do
    visit '/?q=climate'
    expect(page).to have_css 'h4.results'
  end
end
