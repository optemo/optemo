#/* AJAX Functionality */

@module "optemo_module", ->

  #Set up the AJAX send function for use with the back button
  $(document).ready ->
    $.history.init(optemo_module.ajaxsend,{unescape: true})

  #****Public Functions****
  # Submit a categorical filter, e.g. brand.
  @whenDOMready = ->
    optemo_module.SliderInit()
    optemo_module.getRealtimePrices() if (optemo_module? && typeof(optemo_module.getRealtimePrices) == "function")
    optemo_module.load_comparisons()

  @submitAJAX = ->
    selections = $("#filter_form").serializeObject()
    $.each(selections, (k,v) ->
      if(v is "" or v is "-" or v is ";") 
        delete selections[k]
      #/* Slider values shouldn't get sent unless specifically set */
      if(k.match(/superfluous/)) 
        delete selections[k]
    )
    optemo_module.ajaxcall("/compare/create", selections)

  @removeSilkScreen = ->
    $('#silkscreen, #outsidecontainer').hide()
    # For ie 6, dropdown list has z-index issue. Show dropdown when popup hide.
    if($.browser.msie and $.browser.version.substr<7)        
      $('.jumpmenu').show()
    
  @current_height = -> 
    D = document
    return Math.max(
      Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
      Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
      Math.max(D.body.clientHeight, D.documentElement.clientHeight)
    )

  #Optemo's Lightbox effect
  @applySilkScreen = (url,data,width,height,f) ->
    # For ie 6, dropdown list has z-index issue. Hide dropdown when popup show.
    if($.browser.msie and $.browser.version.substr<7)
      $('jumpmenu').hide()
    #IE Compatibility
    iebody= if(document.compatMode and document.compatMode isnt "BackCompat") then document.documentElement else document.body
    dsoctop= if document.all then iebody.scrollTop else window.pageYOffset
    outsidecontainer = $('#outsidecontainer')
    if (outsidecontainer.css('display') isnt 'block') 
      $('#info').html("").css({'height' : "560px", 'width' : (width-46)+'px'})
    outsidecontainer.css(
      'left' : '100px',
      'top' : (dsoctop+5)+'px',
      'width' : (width||560)+'px',
      'display' : 'inline' )
    wWidth = $(window).width()
    $('#silkscreen').css({'height' : optemo_module.current_height()+'px', 'display' : 'inline', 'width' : wWidth + 'px'})
    if (data)
      $('#info').html(data).css('height','')
    else
      quickajaxcall('#info', url, ->
        $('#outsidecontainer').css('width','')
        $('#info').css("height",'')
        if (f)
            f()
      )

  #//--------------------------------------//
  #//                AJAX                  //
  #//--------------------------------------//

  @loading_indicator_state = {spinner_timer : null, socket_error_timer : null, disable : false}

  #/* Does a relatively generic ajax call and returns data to the handler below */
  @ajaxsend = (hash,myurl,mydata) ->
    lis = optemo_module.loading_indicator_state
    #The Optemo category ID should be set in the loader unless this file is loaded non-embedded, then it is set in the opt_discovery section
    mydata = $.extend({'ajax': true, category_id: window.opt_category_id},mydata)
    if (typeof hash isnt "undefined" and hash isnt null and hash isnt "") 
      mydata.hist = hash
    else
      mydata.landing = true
    if (not(lis.spinner_timer)) 
      lis.spinner_timer = setTimeout("optemo_module.start_spinner()", 800)
    val_timeout = 10000
    if (/localhost/.test(myurl) or /192\.168/.test(myurl))
      val_timeout = 100000
    lis.socket_error_timer = setTimeout("optemo_module.ajaxerror()", val_timeout)
    if (window.OPT_REMOTE)
      #Embedded Layout
      myurl = if myurl? then myurl.replace(/http:\/\/[^\/]+/,'') else "/compare"
      # There is a bug in the JSONP implementation. If there is a "?" in the URL, with parameters already on it,
      # this JSONP implementation will add another "?" for the second set of parameters (specified in mydata).
      # For now, just check for a "?" and take those parameters into mydata, 
      # then strip them and the '?' from the URL. -ZAT July 20, 2011
      if (myurl.match(/\?/))
        for contents in myurl[(myurl.indexOf('?') + 1)..-1].split('&')
          data = contents.split('=')
          mydata[data[0]] = data[1]
        myurl = myurl[0...myurl.indexOf('?')]                   
      JSONP.get(window.OPT_REMOTE+myurl,mydata,ajaxhandler)
    else
      $.ajax(
        #type: (mydata==null)?"GET":"POST",
        data: if(typeof mydata is "undefined" or mydata is null) then "" else mydata,
        url: myurl or "/compare",
        success: ajaxhandler,
        error: optemo_module.ajaxerror
      )

  @ajaxerror = ->
    lis = optemo_module.loading_indicator_state
    lis.disable = false
    clearTimeout(lis.spinner_timer) # clearTimeout can run on "null" without error
    optemo_module.stop_spinner()
    clearTimeout(lis.socket_error_timer) # We need to clear the timeout error here
    lis.spinner_timer = lis.socket_error_timer = null
    errorstr = undefined
    if ((typeof(optemo_french) isnt "undefined") and optemo_french)
      errorstr = '<div class="bb_poptitle"><label class="comp-title">Erreur</label><div class="bb_quickview_close"></div></div><p class="error">Désolé! Une erreur est survenue sur le serveur.</p><p>Vous pouvez réinitialiser l\'outil et voir si le problème est résolu.</p>'
    else
      errorstr = '<div class="bb_poptitle"><label class="comp-title">Error</label><div class="bb_quickview_close"></div></div><p class="error">Sorry! An error has occurred on the server.</p><p>You can reload the page and see if the problem is resolved.</p>'
    optemo_module.applySilkScreen(null,errorstr,600,107)
    unless optemo_module.lastpage?
      optemo_module.lastpage = true #Loads the first page after the dialog is closed to try and mitigate the problem. and only do it once

  @ajaxcall = (myurl,mydata) ->
    # Disable interface elements.
    $('.binary_filter, .cat_filter').attr('disabled', true)
    optemo_module.loading_indicator_state.disable = true #Disables any live click handlers and sliders
    
    optemo_module.lasthash = window.location.hash.replace(/^#/, '') #Save the last request hash in case there is an error
    $.history.load($("#actioncount").html(),myurl,mydata)

  #//--------------------------------------//
  #//            Loading Spinner           //
  #//--------------------------------------//

  @start_spinner = ->
    #Show the spinner up top
    viewportwidth = undefined
    viewportheight = undefined
    if window.innerWidth? # (mozilla/netscape/opera/IE7/etc.)
      viewportwidth = window.innerWidth
      viewportheight = window.innerHeight
    else # IE6 and others
      viewportwidth = document.getElementsByTagName('body')[0].clientWidth
      viewportheight = document.getElementsByTagName('body')[0].clientHeight
    $('#loading').css({left: viewportwidth/2 + 'px', top : viewportheight/2 + 'px'}).show()

  @stop_spinner = ->
    $('#loading').hide()

  #****Private Functions****
  quickajaxcall = (element_name, myurl, fn) -> # The purpose of this is to do an ajax load without having to go through the relatively heavy ajaxcall().
    if (window.OPT_REMOTE)
      #Check for absolute urls
      JSONP.get(window.OPT_REMOTE+myurl.replace(/http:\/\/[^\/]+/,''), {embedding:'true', category_id: window.opt_category_id}, (data) ->
        $(element_name).html(data)
        fn() if (fn)
      )
    else
      $(element_name).load(myurl, fn)

  #/* The ajax handler takes data from the ajax call and inserts the data into the #main part and then the #filtering part. */
  ajaxhandler = (data) ->
    lis = optemo_module.loading_indicator_state
    lis.disable = false
    clearTimeout(lis.spinner_timer) # clearTimeout can run on "null" without error
    optemo_module.stop_spinner()
    clearTimeout(lis.socket_error_timer) # We need to clear the timeout error here
    lis.spinner_timer = lis.socket_error_timer = null
    
    parts = data.split('[BRK]')
    if (parts.length == 2) 
      $('#ajaxfilter').empty().append(parts[1])
      $('#main').html(parts[0])
      optemo_module.whenDOMready()
      return 0

  #Serialize an form into a hash, Warning: duplicate keys are dropped
  $.fn.serializeObject = ->
    o = {}
    a = this.serializeArray()
    $.each(a, ->
    #So that multiple checkboxes don't get overwritten, if the value exists, turn it into an array
      if (o[this.name]?)
        o[this.name] = o[this.name] + "*" + this.value or ''
      else
        o[this.name] = this.value or ''
    )
    return o

  #/* LiveInit functions */
  $(".bb_quickview_close, #silkscreen").live 'click', ->
    optemo_module.removeSilkScreen()
    if (optemo_module.lastpage? and optemo_module.lastpage)
      #There was an error in the last request
      $("#actioncount").html(optemo_module.lasthash) #Undo the last action
      optemo_module.ajaxcall("/")
      optemo_module.lastpage = false

  #Pagination links
  $('.pagination a').live "click", ->
    if (optemo_module.loading_indicator_state.disable) 
      return false
    optemo_module.ajaxcall($(this).attr('href'))
    return false
  
  #See all Products
  $('.seeall').live 'click', ->
    optemo_module.ajaxcall('/', {})
    return false
  
  # Change sort method
  $('.sortby').live 'click', ->
    if (optemo_module.loading_indicator_state.disable)
      return false
    optemo_module.ajaxcall("/compare", {"sortby" : $(this).attr('data-feat')})
    return false
  
  #/* End of LiveInit Functions */