Given /^I am on the home page$/ do
  visit "/"
  page.driver.render("tmp/capybara/homepage.png")
end

Then /^I should see "(.*?)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end