#//--------------------------------------//
#//              Cookies                 //
#//--------------------------------------//
@module "optemo_module", ->
  #****Public Functions****
  # This should return all cookie values in an array.
  @readAllCookieValues = (name) ->
    skus = undefined
    cookie = readCookie(name)
    if (cookie) 
      #Remove items that don't match the current product class
      c_product_type = $('#main').attr('data-product_type')
      skus = $.grep cookie.split('*'), (value) ->
        return value.split(',')[1] is c_product_type
      #Remove product_type from cookie values
      skus = $.map skus, (value) ->
        return value.split(',')[0]
    else
      # Fix for cookie not saving but some product checkboxes are checked. Issue found in IE6.
      skus = []
      $(".optemo_compare_checkbox:checked").each (index) ->
          skus.push($(this).attr('data-sku'))
    return skus
  
  @addValueToCookie = (name, value, days) ->
    savedData = readCookie(name)
    numDays = days or 30
    if (savedData)
        # Cookie exists, add additional values with * as the token.
        savedData = opt_appendStringWithToken(savedData, value, '*')
        createCookie(name, savedData, numDays)
    else
        # Cookie does not exist, so just create with the bare value
        createCookie(name, value, numDays)
          
  @removeValueFromCookie = (name, value, days) ->
    savedData = readCookie(name)
    numDays = days or 30
    if (savedData) 
        savedData = opt_removeStringWithToken(savedData, value, '*')
        if (savedData is "") # No values left to store
            optemo_module.eraseCookie(name)
        else
            createCookie(name, savedData, numDays)
    # else do nothing
  
  @eraseCookie = (name) ->
    createCookie(name,"",-1)
  
  #****Private Functions****
  # Add an item to a list with a supplied token - For lists like this: "318*124*19"
  opt_appendStringWithToken = (items, newitem, token) ->
    return (if(items == "") then newitem else items+token+newitem)

  # Remove an item from a list with a supplied token - As above, for removal
  opt_removeStringWithToken = (items, rem, token) ->
    newArray = []
    for item in items.split(token)
      if (item.match(new RegExp("^" + rem)))
        continue
      newArray.push(item)
    newArray.join(token)

  createCookie = (name,value,days) ->
    if (days)
      date = new Date()
      date.setTime(date.getTime()+(days*24*60*60*1000))
      expires = "; expires="+date.toGMTString()
    else
      expires = ""
    document.cookie = name+"="+value+expires+"; path=/"

  readCookie = (name) ->
    nameEQ = name + "="
    for c in document.cookie.split(';')
      while (c[0] ==' ') 
        c = c[1..-1]
      if (c.indexOf(nameEQ) == 0)
        return c[nameEQ.length..-1]
    return null