#/* Fetching the new prices */
@module "optemo_module", ->
  @french_price_format = ( input_price ) ->
    formatted_price = ""
    input_dollars = parseInt(input_price) + ""
    input_cents = parseInt(100 * (input_price - parseInt(input_price)))
    for char, i in input_dollars.split('').reverse()
      formatted_price = char + formatted_price
      formatted_price = ' ' + formatted_price if ((i+1) % 3 == 0 && (input_dollars.length-1) != i)
    return formatted_price + "," + input_cents
    
  @getRealtimePrices = (comparison_flag) ->
    if optemo_module.layout == "fs"
      API_URL = "http://www.futureshop.ca/api/v2/json/search?pagesize=100&query="
    else
      API_URL = "http://www.bestbuy.ca/api/v2/json/search?pagesize=100&query="

    if comparison_flag
      skus = $("#basic_matrix .productinfo").map( ->
        return $(this).attr('data-sku')
      ).toArray().join(" ")
    else # basic call, do this on page load
      skus = $('.productimg, .imageholder').map( -> 
        return $(this).attr('data-sku')
      ).toArray().join(" ")

    if (skus != "")
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
              if !(optemo_module.layout == "fs")
                c.find('.save').show()
                c.find('.saleends').show()
            else
              #No sale
              c.find('.saleprice').hide()
              c.find('.price').show()
              c.find('.save').hide()
              c.find('.saleends').hide()
                        
            #Update the saleprice
            if optemo_module.layout == "fs"
              c.find('.saleprice').find('span.price_dollars').html(parseInt(this.salePrice))
              c.find('.saleprice').find('span.price_cents').html(parseInt(100 * (this.salePrice - parseInt(this.salePrice))))
            else # Do the regular (Best Buy) layout
              if optemo_french?
                c.find('.saleprice > span').html(french_price_format(this.salePrice) + " $")
              else
                c.find('.saleprice > span').html("$" + this.salePrice)

            #Update the regular price
            if optemo_module.layout == "fs"
              c.find('.price').find('span.price_dollars').html(parseInt(this.regularPrice))
              c.find('.price').find('span.price_cents').html(parseInt(100 * (this.regularPrice - parseInt(this.regularPrice))))              
            else
              if optemo_french?
                c.find('.price > span').html(french_price_format(this.regularPrice) + " $")
              else
                c.find('.price > span').html("$" + this.regularPrice)
                
            #Update the savings
            savings = (parseFloat(this.regularPrice)-parseFloat(this.salePrice)).toFixed(2)
            
            if optemo_module.layout == "fs"
              current_savings = c.find('.futureshop_sale_background > span.savings').html()
            else
              current_savings = c.find('.save > span').html()
            
            if current_savings? && !(savings is current_savings or savings is current_savings[1..-1])
              if optemo_module.layout == "fs"
                c.find('.futureshop_sale_background > span.savings').show().html(parseInt(savings))
              else # Best buy layout
                if optemo_french?
                  c.find('.save > span').html(french_price_format(savings) + " $")
                else
                  c.find('.save > span').html("$" + savings)
            #Set checked flag to true
            c.attr("data-checked", true)
          )
          $('.productinfo[data-checked!="true"]').each( ->
            #These products weren't found so remove links
            t = $(this)
            title = t.children(".easylink")
            title.after($('<span>').html(title.html())) unless t.children('span').length
            title.hide()
            #And also remove the add to cart button
            addlink = t.siblings('.shopnowhero') #See if we're dealing with the hero product 
            unless (addlink.length)
              addlink = t #.parent().siblings() #Otherwise we're dealing with the navbox

            # addlink.after($('<div style="text-align: center;">').html(if optemo_french? then "(En rupture de stock)" else "(Out of stock)")).hide()
            #And also remove the link from the image
            t.siblings("img.productimg").removeAttr('title').css({'cursor' : 'default'}).unbind('click') #navbox
            t.parent().siblings("img.productimg").removeAttr('title').css({'cursor' : 'default'}).unbind('click') #Hero
            t.find(".futureshop_price").css({'cursor' : 'default' }).unbind('click') # Futureshop price image
            t.find(".futureshop_sale_background").css({'cursor' : 'default' }).unbind('click') # Futureshop sale price image
          )
      ) # $.ajax()
    # endif skus != blank
  
  #****Public Functions****
  
  #****Private Functions****
  
  #/* LiveInit functions */
  
  #/* End of LiveInit Functions */