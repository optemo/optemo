Feature: Discovery Browsing
	The shopper should be able to look at different products by seeing similar products
	
	Scenario: Click on See Similar
		Given he visits the printers page
		And He clicks continue to see printers
		When he clicks See Similar on the first product
		Then he should see at least six more products
		
	Scenario: Click on lower See Similar