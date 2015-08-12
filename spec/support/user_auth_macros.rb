module UserAuthMacros
  def sign_in
    # user = FactoryGirl.create(:user,
    #                            provider: 'orcid',
    #                            uid: "0000-0002-1825-0097",
    #                            name: "Josiah Carberry",
    #                            email: nil,
    #                            authentication_token: "12345")
    visit "/"
    click_link "Sign in with ORCID"
  end

  def sign_out
    visit "/auth/signout"
  end
end

RSpec.configure do |config|
  config.include UserAuthMacros, type: :feature
end
