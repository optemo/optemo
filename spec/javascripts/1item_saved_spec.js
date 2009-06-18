require("spec_helper.js");
require("../../public/javascripts/application.js");

Screw.Unit(function(){

		before(function() {
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