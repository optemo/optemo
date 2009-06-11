require("spec_helper.js");
require("../../public/javascripts/application.js");

Screw.Unit(function(){

	describe("Empty Saved Items bar", function(){

		describe("When empty ", function() {
			
   			before(function() {
				// Check that there aren't any saved items
   				expect($('.saveditem').length).to(equal,0);
   			});


   			it(" displays the Add Here message", function(){
   				expect($("#deleteme").attr("style")).to(equal,"display:block");
   			});


   			it(" doesn't display the compare button", function(){
   				expect($('#compare_button').attr("style")).to(equal,"display:none");
   			});
   		});
   			
	 	describe("When 1 item added", function() {
 	 		before(function() {
				// Check that saved list is initially empty
 	 			expect($('.saveditem').length).to(equal,0);

				// Save item with ID = 51.
				saveit(51);
			//	additem(51, $('#savebar_content'));
				// TODO this doesn't work.

 	 		});

			it(" has 1 saved item", function(){
 	 			expect($('.saveditem').length).to(equal,1);
			});
     
     		it(" doesn't display the Add Here message", function(){
   				expect($("#deleteme").attr("style")).to(equal,"display:none");
   			});

   			it(" displays the compare button", function(){
   				expect($('#compare_button').attr("style")).to(equal,"display:block");
   			});

	

/*
			describe("When you try to add duplicate item", function() {
	 	 		before(function() {
					// Save the same item
					saveit(38); // TODO such a hack!
	 	 		});

				it(" still contains only 1 item", function(){
	 	 			expect($('.savebar').length).to(equal,1);
				});

	     		it(" doesn't display the Add Here message", function(){
	   				expect(true).to(equal,true);
	   			});

 	 		});
   */  
 	 	});
  	});

});