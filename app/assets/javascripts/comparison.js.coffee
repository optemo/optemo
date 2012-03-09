# Product Comparison */
@module "optemo_module", ->
  #Hardcode the cookie name
  @cmpcookie = 'bestbuy_compare_skus'
  #****Public Functions****
  
  #Check the cookie for comparisons, and the check the appropriate boxes
  @load_comparisons = ->
    skus = optemo_module.readAllCookieValues(optemo_module.cmpcookie)
    $.each skus, (index,sku) ->
       $('.optemo_compare_checkbox[data-sku="'+sku+'"]').each ->
          $(this).attr('checked', 'checked')
          loadspecs(sku)
    changeNavigatorCompareBtn(skus.length)
  
  #****Private Functions****
  #Uncheck box and remove from Compariosn
  removeFromComparison = (sku) ->
    $(".optemo_compare_checkbox").each (index) ->
      if ($(this).attr('data-sku') == sku)
        $(this).attr('checked', '')
        return
    remove_comparison_from_skus(sku)
  
  #Remove from comparison cookie and update comparison count
  remove_comparison_from_skus = (prod_sku) ->
    optemo_module.removeValueFromCookie(optemo_module.cmpcookie, prod_sku+","+window.opt_category_id, 1)
    #Update comparison number
    skus = optemo_module.readAllCookieValues(optemo_module.cmpcookie)
    changeNavigatorCompareBtn(skus.length)
  
  #Check or uncheck a comparison box
  comparison_checkbox_change = ->
    sku_size = optemo_module.readAllCookieValues(optemo_module.cmpcookie).length
    #Differentiate between the checkbox and text link, which passes in the checkbox
    t = (unless arguments[0].jquery? then $(this) else arguments[0])
    if t.is(':checked')  # save the comparison item
      if (sku_size < 5) 
        loadspecs(t.attr('data-sku'))
        optemo_module.addValueToCookie(optemo_module.cmpcookie, t.attr('data-sku')+','+window.opt_category_id, 1)
      else
        if (!(typeof(optemo_french) == "undefined") && optemo_french)
          alert("Le nombre maximum de produits que vous pouvez comparer est de 5. Veuillez réessayer.")
        else
          alert("The maximum number of products you can compare is 5. Please try again.")
        t.attr('checked', '')
    else
      remove_comparison_from_skus(t.attr('data-sku'))
    sku_size = optemo_module.readAllCookieValues(optemo_module.cmpcookie).length
    changeNavigatorCompareBtn(sku_size)
  
  #Update the UI depending on how many comparison items are selected
  changeNavigatorCompareBtn = (selected) ->
    if (selected > 0)
      $('.nav-compare-btn').each ( (index) ->
        $(this).removeClass('awesome_reset_grey')
        $(this).removeClass('global_btn_grey')
        $(this).addClass('awesome_reset')
        $(this).addClass('global_btn')
        $(this).text($(this).text().replace(/\d+/, selected))
      )
      # Show the clear option if it's not visible
      $('.nav_clear_btn:hidden').show()
        
    else
      $('.nav-compare-btn').each ( (index) ->
        $(this).removeClass('awesome_reset')
        $(this).removeClass('global_btn')
        $(this).addClass('awesome_reset_grey')
        $(this).addClass('global_btn_grey')
        $(this).text($(this).text().replace(/\d+/, 0))
      )
      # Hide the clear option if it is visible
      $('.nav_clear_btn:visible').hide()
  
  show_comparison_window = ->
    skus = optemo_module.readAllCookieValues(optemo_module.cmpcookie)
    width = undefined

    return false if skus.length < 1

    # To figure out the width that we need, start with $('#opt_savedproducts').length probably
    # 560 minimum (width is the first of the two parameters)
    # 2, 3, 4 ==>  513, 704, 895  (191 each)
    if (skus.length > 2)
      width = 211 * (skus.length - 2) + 566
    else
      width = 566

    optemo_module.applySilkScreen '/comparison/' + skus.join(","), null, width, 580, ->
      # Jquery 1.5 would finish all the requests before building the comparison matrix once
      # With 1.4.2 we can't do that. Keep code for later.
      # $.when.apply(this,reqs).done();
      buildComparisonMatrix()
    return false
  
  row_height = (length,isLabel) ->
    h
    if (isLabel)
      if (length >= 55) 
        h = 4
      else if (length >= 37) 
        h = 3
      else if (length >= 19) 
        h = 2
      else 
        h = 1
   
    else
      if (length >= 85) 
        h = 4
      else if (length >= 57) 
        h = 3
      else if (length >= 29) 
        h = 2
      else 
        h = 1
   
    return h
  
  #had to change var row_class to rowClass, because function name became a variable name after first call
  row_class = (row_h) ->
    #Assign row_class
    rowClass;
    if (row_h == 4) 
      rowClass = 'quadruple_height_compare_row'
    else if (row_h == 3) 
      rowClass = 'triple_height_compare_row'
    else if (row_h == 2) 
      rowClass = 'double_height_compare_row'
    else 
      rowClass = 'compare_row' # row_class was 1
    return rowClass;
  
  #Collapse some of the cells for large tables
  addtoggle = (item) ->
    closed = item.click( ->
      $(this).toggleClass("closed").toggleClass("open").parent('.cell').parent().next('div.contentholder').toggle()
      return false
    ).hasClass("closed")
    if (closed)
      item.siblings('div').hide()
  
  #Data manipulation for the BB API Interface
  merge_bb_json = ->
    merged = {}
    for arg,index in arguments #for (p = 0; p < arguments.length; p++)
      for own heading,spec of arg
        for own spec_name,value of spec
          if (typeof(merged[heading]) == "undefined")
            merged[heading] = {}
          if (typeof(merged[heading][spec_name]) == "undefined")
            merged[heading][spec_name] = []
          merged[heading][spec_name][index] = value
    return merged
  
  #Build spec matrix from API data
  buildComparisonMatrix = ->
    skus = $('#basic_matrix').attr('data-skus').split(',')
    anchor = $('#hideable_matrix')
    # Build up the direct comparison table. Similar method to views/direct_comparison/index.html.erb
    array = []
    $.each skus, (index,value) ->   #maybe should be $.each skus, do (index,value) -> #(lose bottom thumbnail with this)
      array.push($('body').data('bestbuy_specs_'+value))
      
    grouped_specs = merge_bb_json.apply(null,array)
    #Set up Headers
    for sku,index in skus
      anchor.append('<div class="columntitle spec_column_'+index+' spec-capt">&nbsp;</div>')
      
    result = ""
    whitebg = true
    divContentHolderTag = '<div class="contentholder">'
    divContentHolderTagEnd = '</div>'

    for heading of grouped_specs
      if (heading != "")
        #Add Heading
        result += '<div class="'+row_class(row_height(heading.length,true))+'"><div class="cell ' + (if whitebg then 'whitebg' else 'graybg') + ' leftcolumntext" style="font-style: italic;"><a class="togglable closed title_link" style="font-style: italic;" href="#">' + heading.replace('&','&amp;') + '</a></div>'
        
        for sku,index in skus  
          result += '<div class="cell ' + (if (whitebg) then 'whitebg' else 'graybg') + ' spec_column_'+index+'">&nbsp;</div>'
          
        result += "</div>"
        result += divContentHolderTag
        whitebg = !whitebg
    
      for spec of grouped_specs[heading]
        #Row Height calculation
        array = []

        for i in (grouped_specs[heading][spec])
          if (i)
            array.push(i.length)
        
        #Assign row_class
        result += '<div class="'+row_class(Math.max(row_height(Math.max.apply(null,array)),row_height(spec.length,true))) + '">'
        
        #Row heading
        result += '<div class="cell ' + (if (whitebg) then 'whitebg' else 'graybg') + ' leftcolumntext">' + spec.replace('&','&amp;') + ":</div>"
        #Data
        for sku, index in skus ###############################
          spec_value = grouped_specs[heading][spec][index]
          if (spec_value)
            if (spec_value == "No" || spec_value == "Non") 
              spec_value = "-"

            result += '<div class="cell ' + (if (whitebg) then 'whitebg' else 'graybg') + " " + "spec_column_"+ i + '">' + spec_value.replace(/&/g,'&amp;') + "</div>"
          else
            #Blank Cell
            result += '<div class="cell ' + (if (whitebg) then 'whitebg' else 'graybg') + " " + "spec_column_"+ i + '">-</div>'
          
        result += "</div>"
        whitebg = !whitebg
      
      if (heading != "")
        result += divContentHolderTagEnd
  
    anchor.append(result)

    # Put the thumbnails and such at the bottom of the compare area too (in the hideable matrix)
    remove_row = $('#basic_matrix .compare_row:first')
    anchor.append(
      remove_row.clone(),
      remove_row.next().clone(),
      remove_row.next().next().clone().find('.leftmostcolumntitle').empty().end()
    )
    $('.togglable').each -> 
      addtoggle($(this))
    if ($.browser.msie && $.browser.version.substr(0,1)<7) # IE6 comparison page close button margin space issue
      if (skus.length <= 2)
        $('#optemo_embedder #IE .bb_quickview_close').css("margin-right",'-68px')

  
  # The spec loader works to do a couple AJAX calls when the show page initially loads.
  # The results are stored in $('body').data for instant retrieval when the
  # specs, reviews, or product info buttons are clicked.
  
  # Consider refactoring this code to solve the race condition:
  #   - get the loading code to chain back to the insertion code
  #   - "specs" or "more specs" links just show/hide the table element rather than building it up; the ajax return below does that
  # The disadvantage would be that the specs wouldn't be stored for later retrieval. This probably isn't a big deal.

  # For the bundle products, get the first product from bundle spec and show its specs
  loadspecs = (sku, bundle_sku) ->
    # The jQuery AJAX request will add ?callback=? as appropriate. Best Buy API v.2 supports this.
    baseurl = "http://www.bestbuy.ca/api/v2/json/product/" + sku
    if (!(typeof(optemo_french) == "undefined") && optemo_french) 
      baseurl = baseurl+"?lang=fr"
    # Do the AJAX request only once
    if (!($('body').data('bestbuy_specs_' + sku)))
      $.ajax(
        url: baseurl,
        type: "GET",
        dataType: "jsonp",
        success:  (data) ->
          # If it is a bundle, get the first sku
          bundle = data["bundle"]

          if (bundle.length > 0) 
            loadspecs(bundle[0]["sku"], sku)
          
          else 
            raw_specs = data["specs"]
            # rebuild prop_list so that we can get the specs back out.
            # We might need to do this regardless, due to the fact that
            # the property list doesn't have to be sent in order.
            processed_specs = {}
            for spec in raw_specs
              if (typeof(processed_specs[spec.group]) == "undefined") 
                processed_specs[spec.group] = {}
              processed_specs[spec.group][spec.name] = spec.value
        
            sku_to_register = sku
            if (bundle_sku)
              sku_to_register = bundle_sku
            jQuery('body').data('bestbuy_specs_' + sku_to_register, processed_specs)    
      )
  
  
  #/* LiveInit functions */
  #Remove buttons on compare
  $('.remove').live 'click', ->
    removeFromComparison($(this).attr('data-sku'))
    class_name = $(this).attr('class').split(' ').slice(-1) # spec_column_0, for example

    $("." + class_name).each ->
      $(this).remove()

    # If this is the last one, take the comparison screen down too
    skus = optemo_module.readAllCookieValues(optemo_module.cmpcookie)
    #if (skus.length == 0)
    optemo_module.removeSilkScreen()
    if (skus.length isnt 0)
      show_comparison_window()
    return false
  
  #Clear all comparison options
  $('#optemo_embedder .nav_clear_btn').live "click", ->
    #Uncheck currently checked navboxes
    $('.optemo_compare_checkbox:checked').each ->
      $(this).attr('checked', '')
    #Remove saved cookie values
    optemo_module.eraseCookie(optemo_module.cmpcookie)
    changeNavigatorCompareBtn(0)
    return false
  
  
  #Show/Hide API specs
  $('.toggle_specs').live 'click', ->
    # Once we have the additional specs loaded and rendered, we can simply show and hide that table
    t = $(this)
    t.find(".lesstext").toggle()
    t.find(".moretext").toggle()
    $('#hideable_matrix').toggle()
    cHeight = optemo_module.current_height()
    $('#silkscreen').css({'height' : cHeight+'px', 'display' : 'inline'})
    return false
  
  #Add to comparison from navbox
  $('.optemo_compare_checkbox').live('click', comparison_checkbox_change)
  
  $('.optemo_compare_button').live 'click', ->
	  my_checkbox = $(this).parent().find('.optemo_compare_checkbox')
	  if (!my_checkbox.attr('checked'))
      my_checkbox.attr('checked','checked')
      comparison_checkbox_change(my_checkbox)
    
    if (my_checkbox.is(':checked'))
      show_comparison_window()
    return false
  
  #Comparison btn on navigation page
  $('#optemo_embedder .nav-compare-btn').live("click", show_comparison_window)
  
  #/* End of LiveInit Functions */
