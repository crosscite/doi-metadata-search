require 'spec_helper'

describe 'item', type: :feature, js: true, vcr: true do
  it '/?q=climate' do
    visit '/?q=climate'
    expect(page).to have_css '.list-info'
  end
end
