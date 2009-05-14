require("spec_helper.js");
require("../../public/javascripts/application.js");

Screw.Unit(function(){
  describe("Your application javascript", function(){
    it("does something", function(){
      expect("hello").to(equal, "hello");
    });

    it("accesses the DOM from fixtures/application.html", function(){
      expect($('.select_me').length).to(equal, 0);
    });
  });
  describe("saveItemToSaveds", function(){
	it("adds item (printer) 264 to the saved list", function(){
		saveit(264);
		expect($('#savebar_content').to(equal, "<div id='c264' class='saveditem'>.*"))
	})
  });
});