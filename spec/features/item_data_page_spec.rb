require 'spec_helper'

describe 'item', type: :feature, js: true, vcr: true do
  describe 'metrics tests' do

    it 'when metrics should exist has metrics' do
      visit '/works/10.7272/q6g15xs4'
      expect(page).to have_css 'span.metrics-views'
      expect(page).to have_css 'span.metrics-downloads'
    end

    it 'when metrics should not exist doesnt have has metrics' do
      visit '/works/10.15468/dl.ow2im1'
      expect(page).not_to have_css 'span.metrics-views'
      expect(page).not_to have_css 'span.metrics-downloads'
    end

  end
end
