#/* Fetching the new prices */
@module "optemo_module", ->
  API_URL = "http://www.bestbuy.ca/api/v2/json/search?pagesize=100&query="
  @getRealtimePrices = ->
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
            if (this.salePrice != this.regularPrice && Math.abs(this.regularPrice - this.salePrice) > 0.1) # No floating point error please
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
            if c.find('.saleprice').find('span.price_dollars').length > 0 # We are doing the Futureshop layout
              c.find('.saleprice').find('span.price_dollars').html(parseInt(this.salePrice))
              c.find('.saleprice').find('span.price_cents').html(parseInt(100 * (this.salePrice - parseInt(this.salePrice))))
            else # Do the regular layout
              c.find('.saleprice > span').html((if optemo_french? then "" else "$") + this.salePrice + (if optemo_french? then " $" else ""))

            #Update the regularprice
            if c.find('.price > span.price_dollars') # We are doing the Futureshop layout
              c.find('.price > span.price_dollars').html(parseInt(this.regularPrice))
              c.find('.price > span.price_cents').html(parseInt(100 * (this.regularPrice - parseInt(this.regularPrice))))              
            else # Do the regular layout
              c.find('.price > span').html((if optemo_french? then "" else "$") + this.regularPrice + (if optemo_french? then " $" else ""))
            #Update the savings
            # Check this and fix the code as necessary
            savings = (parseFloat(this.regularPrice)-parseFloat(this.salePrice)).toFixed(2)
            current_savings = c.find('.save > span').html()
            if current_savings? && !(savings is current_savings or savings is current_savings[1..-1])
              if c.find('.saleprice > span.price_dollars') # We are doing the Futureshop layout
                c.find('.futureshop_sale_background > span').html("Save " + (if optemo_french? then "" else "$") + savings + (if optemo_french? then " $" else ""))
              else # Best buy layout
                c.find('.save > span').html((if optemo_french? then "" else "$") + savings + (if optemo_french? then " $" else ""))
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
            addlink = t.siblings('.shopnowhero') #See if we're dealing with the hero product 
            unless (addlink.length)
              addlink = t #.parent().siblings() #Otherwise we're dealing with the navbox

            # addlink.after($('<div style="text-align: center;">').html(if optemo_french? then "(En rupture de stock)" else "(Out of stock)")).hide()
            #And also remove the link from the image
            t.siblings("img.productimg").removeClass("productimg").removeAttr('title') #navbox
            t.parent().siblings("img.productimg").removeClass("productimg").removeAttr('title') #Hero
          )
        
    )
  
  #****Public Functions****
  
  #****Private Functions****
  
  #/* LiveInit functions */
  
  #/* End of LiveInit Functions */