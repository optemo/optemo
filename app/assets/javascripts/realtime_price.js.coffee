#/* Fetching the new prices */
@module "optemo_module", ->
  #****Public Functions****
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
              # This contrived next line eliminates floating point bugs
              c.find('.saleprice').find('span.price_cents').html(Math.round(0.01 * parseInt(10000 * (this.salePrice - parseInt(this.salePrice)))))
            else # Do the regular (Best Buy) layout
              if optemo_french?
                c.find('.saleprice > span').html(price_format(this.salePrice, "fr"))
              else
                c.find('.saleprice > span').html(price_format(this.salePrice, "en"))

            #Update the regular price
            if optemo_module.layout == "fs"
              c.find('.price').find('span.price_dollars').html(parseInt(this.regularPrice))
              c.find('.price').find('span.price_cents').html(Math.round(0.01 * parseInt(10000 * (this.regularPrice - parseInt(this.regularPrice)))))
            else
              if optemo_french?
                c.find('.price > span').html(price_format(this.regularPrice, "fr"))
              else
                c.find('.price > span').html(price_format(this.regularPrice, "en"))
                
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
                  c.find('.save > span').html(price_format(savings, "fr"))
                else
                  c.find('.save > span').html(price_format(savings, "en"))
            #Set checked flag to true
            c.attr("data-checked", true)
            c.siblings(".productimg").addClass("productimgchecked")
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
  
  #****Private Functions****
  price_format = ( input_price, locale ) ->
    formatted_price = ""
    if locale == "en"
      thousand_separator = ","
      cent_separator = "."
    else # locale == "fr"
      thousand_separator = " "
      cent_separator = ","
    input_dollars = parseInt(input_price) + ""
    # Using Math.round in the next line corrects floating point error
    # 17.99 - 17 = 0.9899999999999984 according to Javascript
    input_cents = Math.round(100 * (input_price - parseInt(input_price)))
    for char, i in input_dollars.split('').reverse()
      formatted_price = char + formatted_price
      formatted_price = thousand_separator + formatted_price if ((i+1) % 3 == 0 && (input_dollars.length-1) != i)
    formatted_price = formatted_price + cent_separator + input_cents
    if locale == "en"
      return "$" + formatted_price
    else # locale == "fr"
      return formatted_price + " $"
  
  #/* LiveInit functions */
  
  #/* End of LiveInit Functions */