require 'spec_helper'

describe 'item', type: :feature, js: true, vcr: true do
  describe 'metrics tests' do

    before do
      visit '/works/10.7272/q6g15xs4'
    end

    it 'has metrics views' do
      expect(page).to have_css 'span.metrics-views'
    end

    it 'has metrics downloads' do
      expect(page).to have_css 'span.metrics-downloads'
    end
  end
end
