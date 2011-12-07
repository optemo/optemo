/* Fetching the new prices */

var optemo_module;
optemo_module = (function (my){
  //Don't wait for document ready
  var API_URL = "http://www.bestbuy.ca/api/v2/json/search";
  var API_URL = "http://www.bestbuy.ca/api/v2/json/search?categoryid=20218&pagesize=100&query=";
  var opt_options = {
    'categoryid':'20218',
    'pagesize':'100',
    'query':"10164957%20b9002406"
  };
  //JSONP.get(API_URL, opt_options, function (data) {
  //  alert(data);
  //});
  my.getRealtimePrices = function() {
    var skus = $('.productimg').map(function(){return $(this).attr('data-sku')}).toArray().join(" ");
    $.ajax({
        url: API_URL+skus,
        type: "GET",
        dataType: "jsonp",
        success: function(data){
          $(data["products"]).each(function(i){
            var c = $('.easylink[data-sku="'+this.sku+'"]');
            //Check whether onsale
            if (this.salePrice != this.regularPrice) {
              //We have a sale!
              c.siblings('.saleprice').show();
              c.siblings('.price').hide();
              c.siblings('.save').show();
              c.siblings('.saleends').show();
            } else {
              //No sale
              c.siblings('.saleprice').hide();
              c.siblings('.price').show();
              c.siblings('.save').hide();
              c.siblings('.saleends').hide();
            }
            
            //Update the saleprice
            c.siblings('.saleprice').children('span').html((optemo_french ? "" : "$") + this.salePrice + (optemo_french ? " $" : ""));
            //Update the regularprice
            c.siblings('.price').children('span').html((optemo_french ? "" : "$") + this.regularPrice + (optemo_french ? " $" : ""));
            //Update the savings
            var savings = (parseFloat(this.regularPrice)-parseFloat(this.salePrice)).toFixed(2);
            var current_savings = c.siblings('.save').children('span').html()
            if (!(savings == parseFloat(current_savings) || savings == parseFloat(current_savings.substring(1,current_savings.length)))) {
              c.siblings('.save').children('span').html((optemo_french ? "" : "$") + savings + (optemo_french ? " $" : ""));
              //Remove saleEnd data because we don't have accurate ones
              c.siblings('.saleends').hide();
            }
            
            //Set checked flag to true
            c.attr("data-checked", true);
          });
          $('.easylink[data-checked!="true"]').each(function(){
            //These products weren't found so remove links
            var t = $(this);
            t.after($('<span>').html(t.html()));
            t.hide();
            //And also remove the add to cart button
            t.parent().parent().siblings().hide();
          });
        }
    });
  }
  //****Public Functions****
  
  //****Private Functions****
  
  /* LiveInit functions */
  
  /* End of LiveInit Functions */
  return my;
})(optemo_module || {});
