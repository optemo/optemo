#/* Fetching the new prices */
@module "optemo_module", ->
  API_URL = "http://www.bestbuy.ca/api/v2/json/search?pagesize=100&query="
  optemo_module.getRealtimePrices = () ->
    skus = $('.productimg').map( -> 
      return $(this).attr('data-sku')
    ).toArray().join(" ")
    $.ajax(
        url: API_URL+skus,
        type: "GET",
        dataType: "jsonp",
        success: (data) ->
          $(data["products"]).each( (i) ->
            c = $('.productinfo[data-sku="'+this.sku+'"]')
            #Check whether onsale
            if (this.salePrice != this.regularPrice)
              #We have a sale!
              c.find('.saleprice').show()
              c.find('.price').hide()
              c.find('.save').show()
              c.find('.saleends').show()
            else
              #No sale
              c.find('.saleprice').hide()
              c.find('.price').show()
              c.find('.save').hide()
              c.find('.saleends').hide()
            
            
            #Update the saleprice
            c.find('.saleprice > span').html((if(typeof(optemo_french) isnt "undefined" and optemo_french) then "" else "$") + this.salePrice + (if(typeof(optemo_french) isnt "undefined" and optemo_french) then " $" else ""))
            #Update the regularprice
            c.find('.price > span').html((if(typeof(optemo_french) isnt "undefined" and optemo_french) then "" else "$") + this.regularPrice + (if(typeof(optemo_french) isnt "undefined" and optemo_french) then " $" else ""))
            #Update the savings
            savings = (parseFloat(this.regularPrice)-parseFloat(this.salePrice)).toFixed(2)
            current_savings = c.find('.save > span').html()
            if (not(savings is parseFloat(current_savings) or savings is parseFloat(current_savings.substring(1,current_savings.length)))) 
              c.find('.save > span').html((if(typeof(optemo_french) isnt "undefined" and optemo_french) then "" else "$") + savings + (if(typeof(optemo_french) isnt "undefined" and optemo_french) then " $" else ""))
              #Remove saleEnd data because we don't have accurate ones
              c.find('.saleends').hide()
            
            
            #Set checked flag to true
            c.attr("data-checked", true)
          )
          $('.productinfo[data-checked!="true"]').each( ->
            #These products weren't found so remove links
            t = $(this)
            title = $(this).children(".easylink")
            title.after($('<span>').html(title.html()))
            title.hide()
            #And also remove the add to cart button
            addlink = t.siblings().find('.easylink') #See if we're dealing with the hero product 
            if (!(addlink.length)) 
              addlink = t.parent().siblings() #Otherwise we're dealing with the navbox
            
            addlink.after($('<div style="text-align: center;">').html(if(typeof(optemo_french) isnt "undefined" and optemo_french) then "(En rupture de stock)" else "(Out of stock)")).hide()
            #And also remove the link from the image
            t.siblings("img.productimg").removeClass("productimg").removeAttr('title') #navbox
            t.parent().siblings("img.productimg").removeClass("productimg").removeAttr('title') #Hero
          )
        
    )
  
  #****Public Functions****
  
  #****Private Functions****
  
  #/* LiveInit functions */
  
  #/* End of LiveInit Functions */
  return optemo_module