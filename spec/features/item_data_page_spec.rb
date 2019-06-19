require 'spec_helper'

describe 'item', type: :feature, js: true, vcr: true do
  describe 'usage tests' do

    it 'when usage metrics should be displayed' do
      visit '/works/10.7272/q6g15xs4'
      # Check for usage data spans
      expect(page).to have_css 'a.usage-counts.usage-views'
      expect(page).to have_css 'a.usage-counts.usage-downloads'
      # Check for the charts
      expect(page).to have_css 'div.usage-charts'
    end

    it 'when usage metrics should be hidden' do
      visit '/works/10.21956/aasopenres.13896.r26067'
      expect(page).not_to have_css 'a.usage-counts.usage-views'
      expect(page).not_to have_css 'a.usage-counts.usage-downloads'
    end

    it 'when having citations' do
      visit '/works/10.3886/icpsr29961.v1'
      expect(page).to have_css 'a.usage-counts.citations'
    end
  end
end
