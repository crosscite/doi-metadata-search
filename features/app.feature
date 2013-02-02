Feature: Viewing the home page
	In order to test the sinatra application
	As a user
	I want to view the home page

	Scenario: View home page
		Given I am on the home page
		Then I should see "It works!"