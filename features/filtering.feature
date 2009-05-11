Feature: Filtering
	The shopper filters results based on a brand
	
	Scenario: Filter on Brother
		Given He visits the printers page
		And He clicks continue to see printers
		When He selects Brother
		Then He should see 9 Brother Printers