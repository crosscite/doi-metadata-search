module UserAuthMacros
  def sign_in
    visit "/"
    click_link "Sign in"
  end

  def sign_out
    visit "/auth/signout"
  end
end

RSpec.configure do |config|
  config.include UserAuthMacros, type: :feature
end
