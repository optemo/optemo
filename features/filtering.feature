Feature: Filtering
	The shopper filters results based on a brand
	
	Scenario: Filter on Brother
		Given He visits the printers page
		And He clicks continue to see printers
		When He selects Brother
		Then He should see 9 Brother Printers
		
	Scenario: The shoppper adds two brands
		Given He visits the printers page
		And He clicks continue to see printers
		When He selects Brother
		And He selects Hewlett-Packard
		Then He should see 2 brand selectors
		
	Scenario: The shopper adds a brand and then removes it
		Given He visits the printers page
		And He clicks continue to see printers
		When He selects Brother
		And He removes Brother
		Then He should see 0 brand selectors