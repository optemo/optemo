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
  describe("drawHistogram", function(){
	it("draws the histogram and initializes the slider", function(){
		expect($('.hist').to(contain_selector, 'svg'))
	})
  });
});