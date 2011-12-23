/* Fetching the new prices */

var optemo_module;
optemo_module = (function (my){
  var API_URL = "http://www.bestbuy.ca/api/v2/json/search?pagesize=100&query=";
  my.getRealtimePrices = function() {
    var skus = $('.productimg').map(function(){return $(this).attr('data-sku')}).toArray().join(" ");
    $.ajax({
        url: API_URL+skus,
        type: "GET",
        dataType: "jsonp",
        success: function(data){
          $(data["products"]).each(function(i){
            var c = $('.productinfo[data-sku="'+this.sku+'"]');
            //Check whether onsale
            if (this.salePrice != this.regularPrice) {
              //We have a sale!
              c.find('.saleprice').show();
              c.find('.price').hide();
              c.find('.save').show();
              c.find('.saleends').show();
            } else {
              //No sale
              c.find('.saleprice').hide();
              c.find('.price').show();
              c.find('.save').hide();
              c.find('.saleends').hide();
            }
            
            //Update the saleprice
            c.find('.saleprice > span').html(((typeof(optemo_french) != "undefined" && optemo_french) ? "" : "$") + this.salePrice + ((typeof(optemo_french) != "undefined" && optemo_french) ? " $" : ""));
            //Update the regularprice
            c.find('.price > span').html(((typeof(optemo_french) != "undefined" && optemo_french) ? "" : "$") + this.regularPrice + ((typeof(optemo_french) != "undefined" && optemo_french) ? " $" : ""));
            //Update the savings
            var savings = (parseFloat(this.regularPrice)-parseFloat(this.salePrice)).toFixed(2);
            var current_savings = c.find('.save > span').html()
            if (!(savings == parseFloat(current_savings) || savings == parseFloat(current_savings.substring(1,current_savings.length)))) {
              c.find('.save > span').html(((typeof(optemo_french) != "undefined" && optemo_french) ? "" : "$") + savings + ((typeof(optemo_french) != "undefined" && optemo_french) ? " $" : ""));
              //Remove saleEnd data because we don't have accurate ones
              c.find('.saleends').hide();
            }
            
            //Set checked flag to true
            c.attr("data-checked", true);
          });
          $('.productinfo[data-checked!="true"]').each(function(){
            //These products weren't found so remove links
            var t = $(this).children(".easylink");
            t.after($('<span>').html(t.html()));
            t.hide();
            //And also remove the add to cart button
            var addlink = $(this).siblings().find('.easylink'); //See if we're dealing with the hero product 
            if (!(addlink.length)) {
              addlink = t.parent().parent().siblings();
            }
            addlink.after($('<div style="text-align: center;">').html(optemo_french ? "(En rupture de stock)" : "(Out of stock)")).hide();
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
