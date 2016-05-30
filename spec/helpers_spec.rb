require 'spec_helper'

describe "Helpers", type: :model, vcr: true do
  let(:fixture_path) { "#{Sinatra::Application.root}/spec/fixtures/" }

  subject { ApiSearch.new }

  context "license_img" do
    it "understands CC Zero" do
      license = "https://creativecommons.org/publicdomain/zero/1.0/"
      expect(subject.license_img(license)).to eq("https://licensebuttons.net/p/zero/1.0/80x15.png")
    end
  end
end
